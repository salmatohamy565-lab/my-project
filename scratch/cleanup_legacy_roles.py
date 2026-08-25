import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

sql_cleanup = """
UPDATE public.users 
SET role = 'customer' 
WHERE LOWER(username) IN ('bola', 'eman', 'malak', 'salma', 'dieved', 'abdelkreem') 
   OR LOWER(name) IN ('bola', 'eman', 'malak', 'salma', 'dieved', 'abdelkreem');
"""

with engine.connect() as conn:
    try:
        conn.execute(text(sql_cleanup))
        conn.commit()
        print("[SUCCESS] Generic names (Bola, Salma, Malak, etc.) reset to 'customer' role so only distinguished usernames access Admin/Employee dashboards!")
    except Exception as e:
        print("[ERROR] Cleanup failed:", e)
