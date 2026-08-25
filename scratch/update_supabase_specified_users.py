import psycopg2
import sys
from werkzeug.security import generate_password_hash

sys.stdout.reconfigure(encoding='utf-8')
db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

accounts = [
    {
        "email": "boladesigns111@gmail.com",
        "username": "boladesigns111",
        "name": "مدير النظام (Bola Designs)",
        "role": "admin",
        "password": "123456"
    },
    {
        "email": "malakmoatsem30@gmail.com",
        "username": "malakmoatsem30",
        "name": "ملك معتصم (موظفة)",
        "role": "employee",
        "password": "123456"
    },
    {
        "email": "salmatohamy565@gmail.com",
        "username": "salmatohamy565",
        "name": "سلمى التهامي (موظفة)",
        "role": "employee",
        "password": "123456"
    }
]

try:
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    for acc in accounts:
        pass_hash = generate_password_hash(acc["password"])
        cur.execute("""
        INSERT INTO users (username, email, name, role, password_hash)
        VALUES (%s, %s, %s, %s, %s)
        ON CONFLICT (username) DO UPDATE 
        SET email = EXCLUDED.email,
            name = EXCLUDED.name,
            role = EXCLUDED.role,
            password_hash = EXCLUDED.password_hash;
        """, (acc["username"], acc["email"], acc["name"], acc["role"], pass_hash))

        # Also update by email if match
        cur.execute("""
        UPDATE users 
        SET role = %s, password_hash = %s, name = %s
        WHERE LOWER(email) = LOWER(%s);
        """, (acc["role"], pass_hash, acc["name"], acc["email"]))

    conn.commit()
    print("[SUPABASE USERS UPDATE] Successfully configured Admin & Employee accounts in Supabase DB!")

    cur.execute("SELECT id, username, email, role FROM users WHERE LOWER(email) IN ('boladesigns111@gmail.com', 'malakmoatsem30@gmail.com', 'salmatohamy565@gmail.com');")
    rows = cur.fetchall()
    print("\n--- Configured Accounts in Supabase DB ---")
    for r in rows:
        print(f"ID: {r[0]}, Username: {r[1]}, Email: {r[2]}, Role: {r[3]}")

    cur.close()
    conn.close()
except Exception as e:
    print(f"[SUPABASE USERS UPDATE ERROR] {e}")
