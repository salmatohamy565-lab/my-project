import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

with engine.connect() as conn:
    print("--- Updating salmaa.2004wael password_hash to plain text ---")
    try:
        # Check password for salmaa.2004wael or update to plain text
        res = conn.execute(text("UPDATE users SET password_hash = '123456' WHERE username = 'salmaa.2004wael';"))
        conn.commit()
        print(f"[SUCCESS] Updated {res.rowcount} row(s) for salmaa.2004wael to plain text password '123456'!")
    except Exception as e:
        print("[ERROR] Failed updating salmaa.2004wael password:", e)
