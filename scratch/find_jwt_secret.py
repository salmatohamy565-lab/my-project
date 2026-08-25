import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

with engine.connect() as conn:
    print("--- Searching PG settings for JWT / Supabase keys ---")
    try:
        res = conn.execute(text("SELECT name, setting FROM pg_settings WHERE name LIKE '%jwt%' OR name LIKE '%auth%' OR name LIKE '%pgrst%';"))
        for r in res:
            print(f"Setting: {r.name} = {r.setting}")
    except Exception as e:
        print("pg_settings error:", e)

    print("\n--- Searching auth schema / config ---")
    try:
        res = conn.execute(text("SELECT * FROM auth.schema_migrations;"))
        for r in res:
            print(r)
    except Exception as e:
        print("schema_migrations error:", e)
