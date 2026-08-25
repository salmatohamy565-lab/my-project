import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

with engine.connect() as conn:
    print("--- Inspecting auth.identities ---")
    try:
        res = conn.execute(text("SELECT * FROM auth.identities LIMIT 10;")).fetchall()
        print(f"Total rows in auth.identities: {len(res)}")
        for r in res:
            print(dict(r._mapping))
    except Exception as e:
        print("auth.identities error:", e)
