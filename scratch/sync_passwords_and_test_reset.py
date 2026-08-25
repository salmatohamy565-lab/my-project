import os
import sys
import bcrypt
from werkzeug.security import generate_password_hash
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

target_password = "123456"

# Generate hashes for '123456'
werkzeug_hash = generate_password_hash(target_password)
bcrypt_hash = bcrypt.hashpw(target_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

print(f"Werkzeug Hash for '{target_password}': {werkzeug_hash}")
print(f"Bcrypt Hash for '{target_password}': {bcrypt_hash}")

with engine.connect() as conn:
    print("\n--- Syncing passwords for all accounts in public.users and auth.users ---")
    try:
        # Update public.users
        res_public = conn.execute(text("UPDATE users SET password_hash = :w_hash;"), {"w_hash": werkzeug_hash})
        print(f"[SUCCESS] Updated {res_public.rowcount} users in public.users to password '{target_password}'!")
        
        # Update auth.users
        res_auth = conn.execute(text("UPDATE auth.users SET encrypted_password = :b_hash;"), {"b_hash": bcrypt_hash})
        print(f"[SUCCESS] Updated {res_auth.rowcount} users in auth.users to password '{target_password}'!")
        
        conn.commit()
    except Exception as e:
        print("[ERROR] Failed updating passwords:", e)
