import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

with engine.connect() as conn:
    print("--- Inspecting auth.users columns & constraints ---")
    try:
        res = conn.execute(text("SELECT id, email, confirmed_at, email_confirmed_at, instance_id, aud, role FROM auth.users LIMIT 5;"))
        for r in res:
            print(dict(r._mapping))
    except Exception as e:
        print("Error inspecting auth.users:", e)
