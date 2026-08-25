import sys
import io
import psycopg2

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

print("--- ALL CATEGORIES ---")
cur.execute("SELECT id, name FROM categories ORDER BY id ASC;")
for c in cur.fetchall():
    print(c)

print("\n--- ALL SUBCATEGORIES ---")
cur.execute("SELECT id, name, category_id FROM subcategories ORDER BY id ASC;")
for s in cur.fetchall():
    print(s)

cur.close()
conn.close()
