import sys
import io
import psycopg2

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

print("Connecting to PostgreSQL Database...")
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# Check foreign keys on 'orders' table
cur.execute("""
    SELECT
        tc.constraint_name, 
        kcu.column_name, 
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name 
    FROM information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name='orders';
""")
fks = cur.fetchall()
print("\n--- FOREIGN KEYS ON 'orders' TABLE ---")
for fk in fks:
    print(f"Constraint: {fk[0]} | Col: {fk[1]} -> Foreign: {fk[2]}({fk[3]})")

cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'users';")
print("\n--- COLUMNS IN 'users' TABLE ---")
print([c[0] for c in cur.fetchall()])

cur.close()
conn.close()
