import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

trigger_sql = """
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
        print("[SUCCESS] Created trigger 'trg_sync_auth_password_to_public' on auth.users!")
    except Exception as e:
        print("[ERROR] Failed creating password sync trigger:", e)
