import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

trigger_sql = """
CREATE OR REPLACE FUNCTION public.sync_public_user_to_auth_users()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.email IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM auth.users WHERE LOWER(email) = LOWER(NEW.email)
    ) THEN
        INSERT INTO auth.users (
            instance_id, id, aud, role, email, encrypted_password, 
            email_confirmed_at, raw_app_meta_data, raw_user_meta_data, 
            created_at, updated_at, is_super_admin
        ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            gen_random_uuid(), 'authenticated', 'authenticated', LOWER(NEW.email), '', 
            NOW(), '{"provider":"email","providers":["email"]}', '{}', 
            NOW(), NOW(), false
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_public_user_to_auth ON public.users;

CREATE TRIGGER trg_sync_public_user_to_auth
AFTER INSERT OR UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.sync_public_user_to_auth_users();
"""

with engine.connect() as conn:
    try:
        conn.execute(text(trigger_sql))
        conn.commit()
        print("[SUCCESS] Created PostgreSQL trigger 'trg_sync_public_user_to_auth' on public.users!")
    except Exception as e:
        print("[ERROR] Failed creating trigger:", e)
