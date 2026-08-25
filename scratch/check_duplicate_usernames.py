import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

with engine.connect() as conn:
    print("--- Checking duplicate usernames in public.users ---")
    res = conn.execute(text("""
        SELECT LOWER(username) as lower_username, COUNT(*) 
        FROM users 
        GROUP BY LOWER(username) 
        HAVING COUNT(*) > 1;
    """))
    dups = res.fetchall()
    if dups:
        print("[DUPLICATES FOUND]:", dups)
    else:
        print("[SUCCESS] No duplicate usernames found in public.users!")

    print("\n--- Checking columns in public.users ---")
    cols = conn.execute(text("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'users' AND table_schema = 'public';
    """)).fetchall()
    for col in cols:
        print(f"  - {col[0]}: {col[1]}")
