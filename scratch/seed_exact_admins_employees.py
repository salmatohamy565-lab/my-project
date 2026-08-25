import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

admins = [
    {"name": "Bola", "username": "Bola", "email": "bola@boladesigns.com", "password": "78945612300"},
    {"name": "Eman", "username": "Eman", "email": "eman@boladesigns.com", "password": "admin123"},
]

employees = [
    {"name": "Malak", "username": "Malak", "email": "malak@boladesigns.com", "password": "emp123"},
    {"name": "Salma", "username": "Salma", "email": "salma@boladesigns.com", "password": "emp123"},
    {"name": "dieved", "username": "dieved", "email": "dieved@boladesigns.com", "password": "emp123"},
    {"name": "Abdelkreem", "username": "Abdelkreem", "email": "abdelkreem@boladesigns.com", "password": "emp123"},
]

with engine.connect() as conn:
    print("--- Seeding exact Admins ---")
    for adm in admins:
        conn.execute(text("""
            DELETE FROM public.users WHERE LOWER(username) = LOWER(:username) OR LOWER(email) = LOWER(:email);
            INSERT INTO public.users (username, name, email, role, password_hash, created_at)
            VALUES (:username, :name, :email, 'admin', :password, NOW());

            DELETE FROM auth.users WHERE LOWER(email) = LOWER(:email);
            INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role)
            VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000000', :email, :password, NOW(), '{"provider":"email","providers":["email"]}', jsonb_build_object('username', :username), NOW(), NOW(), 'authenticated');
        """), adm)
        conn.commit()
        print(f"[SUCCESS] Seeded Admin: {adm['username']}")

    print("\n--- Seeding exact Employees ---")
    for emp in employees:
        conn.execute(text("""
            DELETE FROM public.users WHERE LOWER(username) = LOWER(:username) OR LOWER(email) = LOWER(:email);
            INSERT INTO public.users (username, name, email, role, password_hash, created_at)
            VALUES (:username, :name, :email, 'employee', :password, NOW());

            DELETE FROM auth.users WHERE LOWER(email) = LOWER(:email);
            INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role)
            VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000000', :email, :password, NOW(), '{"provider":"email","providers":["email"]}', jsonb_build_object('username', :username), NOW(), NOW(), 'authenticated');
        """), emp)
        conn.commit()
        print(f"[SUCCESS] Seeded Employee: {emp['username']}")
