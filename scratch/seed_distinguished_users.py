import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

distinguished_admins = [
    {"name": "Bola (Admin)", "username": "admin_bola_01", "phone": "01000000001", "email": "admin.bola.01@boladesigns.com"},
    {"name": "Eman (Admin)", "username": "admin_eman_02", "phone": "01000000002", "email": "admin.eman.02@boladesigns.com"},
]

distinguished_employees = [
    {"name": "Malak (Employee)", "username": "emp_malak_101", "phone": "01100000101", "email": "emp.malak.101@boladesigns.com"},
    {"name": "Salma (Employee)", "username": "emp_salma_102", "phone": "01100000102", "email": "emp.salma.102@boladesigns.com"},
    {"name": "dieved (Employee)", "username": "emp_dieved_103", "phone": "01100000103", "email": "emp.dieved.103@boladesigns.com"},
    {"name": "Abdelkreem (Employee)", "username": "emp_abdelkreem_104", "phone": "01100000104", "email": "emp.abdelkreem.104@boladesigns.com"},
]

with engine.connect() as conn:
    print("--- Seeding Distinguished Admins ---")
    for adm in distinguished_admins:
        conn.execute(text("""
            DELETE FROM public.users WHERE LOWER(username) = LOWER(:username) OR LOWER(email) = LOWER(:email);
            INSERT INTO public.users (username, name, email, phone, role, password_hash, created_at)
            VALUES (:username, :name, :email, :phone, 'admin', 'passwordless', NOW());

            DELETE FROM auth.users WHERE LOWER(email) = LOWER(:email);
            INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role)
            VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000000', :email, 'passwordless', NOW(), '{"provider":"email","providers":["email"]}', jsonb_build_object('username', :username), NOW(), NOW(), 'authenticated');
        """), adm)
        conn.commit()
        print(f"[SUCCESS] Seeded Admin: {adm['username']} (Phone: {adm['phone']})")

    print("\n--- Seeding Distinguished Employees ---")
    for emp in distinguished_employees:
        conn.execute(text("""
            DELETE FROM public.users WHERE LOWER(username) = LOWER(:username) OR LOWER(email) = LOWER(:email);
            INSERT INTO public.users (username, name, email, phone, role, password_hash, created_at)
            VALUES (:username, :name, :email, :phone, 'employee', 'passwordless', NOW());

            DELETE FROM auth.users WHERE LOWER(email) = LOWER(:email);
            INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role)
            VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000000', :email, 'passwordless', NOW(), '{"provider":"email","providers":["email"]}', jsonb_build_object('username', :username), NOW(), NOW(), 'authenticated');
        """), emp)
        conn.commit()
        print(f"[SUCCESS] Seeded Employee: {emp['username']} (Phone: {emp['phone']})")
