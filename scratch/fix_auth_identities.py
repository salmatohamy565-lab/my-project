import os
import sys
import json
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

with engine.connect() as conn:
    print("--- Populating auth.identities with provider_id ---")
    users = conn.execute(text("SELECT id, email FROM auth.users;")).fetchall()
    print(f"Found {len(users)} users in auth.users")

    for u in users:
        u_id = str(u.id)
        email = u.email.strip().lower()
        identity_data = json.dumps({"sub": u_id, "email": email, "email_verified": True})
        
        try:
            existing = conn.execute(text("SELECT id FROM auth.identities WHERE user_id = :u_id"), {"u_id": u_id}).first()
            if not existing:
                query = text("""
                    INSERT INTO auth.identities (
                        id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
                    ) VALUES (
                        gen_random_uuid(), :u_id, :u_id, :identity_data, 'email', NOW(), NOW(), NOW()
                    );
                """)
                conn.execute(query, {"u_id": u_id, "identity_data": identity_data})
                conn.commit()
                print(f"  [SUCCESS] Created identity for {email}")
            else:
                print(f"  [EXISTS] Identity already exists for {email}")
        except Exception as e:
            print(f"  [ERROR] {email}: {e}")
            conn.rollback()
