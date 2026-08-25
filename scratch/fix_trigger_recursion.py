import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

trigger_sql = """
-- Prevent recursion in public.users trigger
CREATE OR REPLACE FUNCTION public.sync_public_user_to_auth_users()
RETURNS TRIGGER AS $$
DECLARE
    new_user_id UUID;
    clean_email TEXT;
BEGIN
    IF pg_trigger_depth() > 1 THEN
        RETURN NEW;
    END IF;

    IF NEW.email IS NOT NULL THEN
        clean_email := LOWER(TRIM(NEW.email));
        
        SELECT id INTO new_user_id FROM auth.users WHERE LOWER(email) = clean_email LIMIT 1;
        
        IF new_user_id IS NULL THEN
            new_user_id := gen_random_uuid();
            
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
            IF NEW.password_hash IS NOT NULL AND NEW.password_hash != '' THEN
                UPDATE auth.users 
                SET encrypted_password = NEW.password_hash, updated_at = NOW() 
                WHERE id = new_user_id AND encrypted_password IS DISTINCT FROM NEW.password_hash;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Prevent recursion in auth.users trigger
CREATE OR REPLACE FUNCTION public.sync_auth_password_to_public_users()
RETURNS TRIGGER AS $$
BEGIN
    IF pg_trigger_depth() > 1 THEN
        RETURN NEW;
    END IF;

    IF NEW.email IS NOT NULL AND NEW.encrypted_password IS NOT NULL AND NEW.encrypted_password != '' THEN
        UPDATE public.users 
        SET password_hash = NEW.encrypted_password 
        WHERE LOWER(email) = LOWER(NEW.email) AND password_hash IS DISTINCT FROM NEW.encrypted_password;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
"""

with engine.connect() as conn:
    try:
        conn.execute(text(trigger_sql))
        conn.commit()
        print("[SUCCESS] Added pg_trigger_depth() > 1 checks to eliminate recursion!")
    except Exception as e:
        print("[ERROR] Failed updating triggers:", e)
