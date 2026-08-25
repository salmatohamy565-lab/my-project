import psycopg2
import sys
from werkzeug.security import generate_password_hash

sys.stdout.reconfigure(encoding='utf-8')
db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    email = "salmatohamy565@gmail.com"
    username = "salmatohamy565"
    name = "سلمى التهامي"
    pass_hash = generate_password_hash("123456")

    # Insert user if not exists
    cur.execute("""
    INSERT INTO users (username, email, name, role, password_hash)
    VALUES (%s, %s, %s, %s, %s)
    ON CONFLICT (username) DO UPDATE SET email = EXCLUDED.email;
    """, (username, email, name, "customer", pass_hash))

    conn.commit()
    print(f"[SUPABASE DB SUCCESS] Created user account for {email} in Supabase DB!")

    cur.close()
    conn.close()
except Exception as e:
    print(f"Error registering user: {e}")
