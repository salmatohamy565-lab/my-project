import os
import sys

sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = os.environ.get("DATABASE_URL") or "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

try:
    engine = create_engine(db_url)
    with engine.connect() as conn:
        res = conn.execute(text("SELECT id, email, code, created_at, expires_at FROM otp_codes ORDER BY id DESC LIMIT 5;"))
        print("--- Recent OTP Codes in Supabase DB (otp_codes table) ---")
        for r in res:
            print(f"ID: {r.id}, Email: {r.email}, Code: {r.code}, Created: {r.created_at}, Expires: {r.expires_at}")
except Exception as e:
    print(f"Error querying Supabase DB via SQLAlchemy: {e}")
