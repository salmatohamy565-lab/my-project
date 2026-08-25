import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

with engine.connect() as conn:
    print("--- Updating public.users password_hash to plain text '123456' ---")
    try:
        res = conn.execute(text("UPDATE users SET password_hash = '123456';"))
        conn.commit()
        print(f"[SUCCESS] Updated {res.rowcount} rows in public.users to plain text password '123456'!")
    except Exception as e:
        print("[ERROR] Failed updating public.users:", e)
