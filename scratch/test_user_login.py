import psycopg2
import sys
from werkzeug.security import check_password_hash

sys.stdout.reconfigure(encoding='utf-8')
db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    cur.execute("SELECT id, username, email, role, password_hash FROM users;")
    rows = cur.fetchall()
    print("--- Current Registered Accounts in Supabase Database ---")
    for r in rows:
        uid, uname, email, role, phash = r
        is_pass_123456 = check_password_hash(phash, "123456") if phash else False
        print(f"ID: {uid} | Username: {uname} | Email: {email} | Role: {role} | Pass 123456 Match: {is_pass_123456}")

    cur.close()
    conn.close()
except Exception as e:
    print(f"Error querying Supabase DB: {e}")
