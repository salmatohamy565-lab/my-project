import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

with engine.connect() as conn:
    print("--- Searching for 'malak' in public.users ---")
    res = conn.execute(text("SELECT id, username, name, email, phone, role, failed_login_attempts, locked_until FROM public.users WHERE LOWER(username) LIKE '%malak%' OR LOWER(name) LIKE '%malak%';")).fetchall()
    for row in res:
        print(f"ID: {row[0]}, Username: '{row[1]}', Name: '{row[2]}', Email: '{row[3]}', Phone: '{row[4]}', Role: '{row[5]}', FailedAttempts: {row[6]}, LockedUntil: {row[7]}")
