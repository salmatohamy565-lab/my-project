import os
import sys
import uuid
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

with engine.connect() as conn:
    # Fetch all public users
    users = conn.execute(text("SELECT id, username, email, password_hash FROM users WHERE email IS NOT NULL;")).fetchall()
    print(f"Found {len(users)} users in public.users")

    for u in users:
        user_id = str(uuid.uuid4())
        email = u.email.strip().lower()
        print(f"Syncing user {email} to auth.users...")
        try:
            # Check if user already exists in auth.users
            existing = conn.execute(text("SELECT id FROM auth.users WHERE LOWER(email) = :email"), {"email": email}).first()
            if not existing:
                query = text("""
                    INSERT INTO auth.users (
                        instance_id, id, aud, role, email, encrypted_password, 
                        email_confirmed_at, raw_app_meta_data, raw_user_meta_data, 
                        created_at, updated_at, is_super_admin
                    ) VALUES (
                        '00000000-0000-0000-0000-000000000000',
                        :id, 'authenticated', 'authenticated', :email, '', 
                        NOW(), '{"provider":"email","providers":["email"]}', '{}', 
                        NOW(), NOW(), false
                    );
                """)
                conn.execute(query, {"id": user_id, "email": email})
                conn.commit()
                print(f"  [SUCCESS] Synced {email} into auth.users (UUID: {user_id})")
            else:
                print(f"  [EXISTS] {email} already exists in auth.users (UUID: {existing.id})")
        except Exception as e:
            print(f"  [ERROR] {email}: {e}")
