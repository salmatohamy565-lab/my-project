import psycopg2
import sys
from werkzeug.security import generate_password_hash

sys.stdout.reconfigure(encoding='utf-8')
db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    pass_hash = generate_password_hash("123456")

    # Update all accounts password to 123456
    cur.execute("UPDATE users SET password_hash = %s;", (pass_hash,))
    conn.commit()
    print("[SUPABASE DB SUCCESS] Reset all account passwords to '123456'!")

    cur.execute("SELECT id, username, email, role FROM users;")
    rows = cur.fetchall()
    print("\n--- All Accounts in Supabase DB (Password: 123456) ---")
    for r in rows:
        print(f"ID: {r[0]} | Username: {r[1]} | Email: {r[2]} | Role: {r[3]}")

    cur.close()
    conn.close()
except Exception as e:
    print(f"Error resetting passwords in Supabase DB: {e}")
