import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text, or_, func

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

email = "salmaa.2004wael@gmail.com"

with engine.connect() as conn:
    clean = str(email).strip().lower()
    prefix = clean.split('@')[0] if '@' in clean else clean
    print(f"Testing search for clean='{clean}', prefix='{prefix}'")
    
    query = text("""
        SELECT id, username, email FROM users 
        WHERE LOWER(username) = :clean OR LOWER(email) = :clean 
           OR LOWER(username) = :prefix OR LOWER(email) = :prefix
    """)
    res = conn.execute(query, {"clean": clean, "prefix": prefix}).first()
    print("Found user:", res)
