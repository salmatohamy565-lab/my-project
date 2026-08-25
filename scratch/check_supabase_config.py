import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

with engine.connect() as conn:
    print("--- Users in auth.users ---")
    try:
        res = conn.execute(text("SELECT id, email, created_at FROM auth.users LIMIT 10;"))
        for r in res:
            print(f"Auth User -> ID: {r.id}, Email: {r.email}")
    except Exception as e:
        print("auth.users error:", e)

    print("\n--- Users in public.users ---")
    try:
        res = conn.execute(text("SELECT id, username, email, role FROM users LIMIT 10;"))
        for r in res:
            print(f"Public User -> ID: {r.id}, Username: {r.username}, Email: {r.email}, Role: {r.role}")
    except Exception as e:
        print("public.users error:", e)
