import psycopg2
import sys

sys.stdout.reconfigure(encoding='utf-8')
db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    cur.execute("SELECT id, username, email, name, role FROM users;")
    rows = cur.fetchall()
    print("--- Current Registered Users in Supabase DB ---")
    for r in rows:
        print(f"ID: {r[0]}, Username: {r[1]}, Email: {r[2]}, Name: {r[3]}, Role: {r[4]}")

    cur.close()
    conn.close()
except Exception as e:
    print(f"Error querying users from Supabase DB: {e}")
