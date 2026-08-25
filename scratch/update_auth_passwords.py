import os
import sys
import bcrypt
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

# Generate valid bcrypt hash for '123456'
password = "123456".encode('utf-8')
hashed_pw = bcrypt.hashpw(password, bcrypt.gensalt()).decode('utf-8')

print(f"Generated bcrypt hash for '123456': {hashed_pw}")

with engine.connect() as conn:
    print("--- Updating auth.users encrypted_password with valid bcrypt hash ---")
    try:
        conn.execute(text("UPDATE auth.users SET encrypted_password = :hash WHERE encrypted_password = '' OR encrypted_password IS NULL;"), {"hash": hashed_pw})
        conn.commit()
        print("[SUCCESS] Updated all auth.users encrypted_password with valid bcrypt hash for password '123456'!")
    except Exception as e:
        print("[ERROR] Failed updating encrypted_password:", e)
