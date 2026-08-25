import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

sql_script = """
-- 1. Ensure Admin User in public.users
DELETE FROM public.users WHERE LOWER(username) = 'admin' OR LOWER(email) = 'admin@boladesigns.com';

INSERT INTO public.users (username, name, email, phone, role, password_hash, created_at)
VALUES ('admin', 'المدير العام', 'admin@boladesigns.com', '01000000000', 'admin', 'passwordless', NOW());

-- Ensure Admin User in auth.users
DELETE FROM auth.users WHERE LOWER(email) = 'admin@boladesigns.com';

INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role)
VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'admin@boladesigns.com', 'passwordless', NOW(), '{"provider":"email","providers":["email"]}', '{"username":"admin"}', NOW(), NOW(), 'authenticated');


-- 2. Ensure Employee User in public.users
DELETE FROM public.users WHERE LOWER(username) = 'employee' OR LOWER(email) = 'employee@boladesigns.com';

INSERT INTO public.users (username, name, email, phone, role, password_hash, created_at)
VALUES ('employee', 'الموظف المسئول', 'employee@boladesigns.com', '01100000000', 'employee', 'passwordless', NOW());

-- Ensure Employee User in auth.users
DELETE FROM auth.users WHERE LOWER(email) = 'employee@boladesigns.com';

INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role)
VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000000', 'employee@boladesigns.com', 'passwordless', NOW(), '{"provider":"email","providers":["email"]}', '{"username":"employee"}', NOW(), NOW(), 'authenticated');
"""

with engine.connect() as conn:
    try:
        conn.execute(text(sql_script))
        conn.commit()
        print("[SUCCESS] Setup Admin (admin / 01000000000) and Employee (employee / 01100000000) successfully!")
    except Exception as e:
        print("[ERROR] Failed setting up dedicated users:", e)
