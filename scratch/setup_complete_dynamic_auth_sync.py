import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

trigger_sql = """
-- 1. Trigger from public.users to auth.users when a user signs up or updates password
CREATE OR REPLACE FUNCTION public.sync_public_user_to_auth_users()
RETURNS TRIGGER AS $$
DECLARE
    new_user_id UUID;
    clean_email TEXT;
BEGIN
    IF NEW.email IS NOT NULL THEN
        clean_email := LOWER(TRIM(NEW.email));
        
        -- Find existing user in auth.users
        SELECT id INTO new_user_id FROM auth.users WHERE LOWER(email) = clean_email LIMIT 1;
        
        IF new_user_id IS NULL THEN
            new_user_id := gen_random_uuid();
            
            -- Insert new user into auth.users with their real password_hash
            INSERT INTO auth.users (
                instance_id, id, aud, role, email, encrypted_password, 
                email_confirmed_at, raw_app_meta_data, raw_user_meta_data, 
                created_at, updated_at, is_super_admin
            ) VALUES (
                '00000000-0000-0000-0000-000000000000',
                new_user_id, 'authenticated', 'authenticated', clean_email, COALESCE(NEW.password_hash, ''), 
                NOW(), '{"provider":"email","providers":["email"]}', '{}', 
                NOW(), NOW(), false
            );
            
            -- Insert into auth.identities
            INSERT INTO auth.identities (
                id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
            ) VALUES (
                gen_random_uuid(), 
                new_user_id, 
                new_user_id::text, 
                jsonb_build_object('sub', new_user_id::text, 'email', clean_email, 'email_verified', true), 
                'email', 
                NOW(), 
                NOW(), 
                NOW()
            );
        ELSE
            -- If user exists and password_hash changed in public.users, update auth.users
            IF NEW.password_hash IS NOT NULL AND NEW.password_hash != '' THEN
                UPDATE auth.users 
                SET encrypted_password = NEW.password_hash, updated_at = NOW() 
                WHERE id = new_user_id;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_public_user_to_auth ON public.users;
CREATE TRIGGER trg_sync_public_user_to_auth
AFTER INSERT OR UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.sync_public_user_to_auth_users();


-- 2. Trigger from auth.users to public.users when password is reset via OTP
CREATE OR REPLACE FUNCTION public.sync_auth_password_to_public_users()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.email IS NOT NULL AND NEW.encrypted_password IS NOT NULL AND NEW.encrypted_password != '' THEN
        UPDATE public.users 
        SET password_hash = NEW.encrypted_password 
        WHERE LOWER(email) = LOWER(NEW.email);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_auth_password_to_public ON auth.users;
CREATE TRIGGER trg_sync_auth_password_to_public
AFTER UPDATE OF encrypted_password ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.sync_auth_password_to_public_users();
"""

with engine.connect() as conn:
    try:
        conn.execute(text(trigger_sql))
        conn.commit()
        print("[SUCCESS] Fully configured dynamic 2-way password & account sync between public.users and auth.users!")
    except Exception as e:
        print("[ERROR] Failed setting up triggers:", e)
