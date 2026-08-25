import psycopg2
import sys
from werkzeug.security import generate_password_hash

sys.stdout.reconfigure(encoding='utf-8')
db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()
    
    # Update password for Bola to '123456' hashed
    new_hash = generate_password_hash('123456')
    cur.execute("UPDATE users SET password_hash = %s WHERE username = 'Bola' OR email = 'bola@boladesigns.com';", (new_hash,))
    conn.commit()
    print("Updated password hash for user Bola to hashed '123456'")
    
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error updating user password: {e}")
