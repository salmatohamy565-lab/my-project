import sys
import io
import psycopg2

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

print("Connecting to PostgreSQL Database...")
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# 1. Inspect RLS status and policies on 'orders' table
cur.execute("""
    SELECT relrowsecurity 
    FROM pg_class 
    WHERE relname = 'orders';
""")
rls_enabled = cur.fetchone()[0]
print(f"RLS enabled on 'orders' table: {rls_enabled}")

cur.execute("""
    SELECT policyname, roles, cmd, qual, with_check 
    FROM pg_policies 
    WHERE tablename = 'orders';
""")
policies = cur.fetchall()
print("\n--- RLS POLICIES ON 'orders' TABLE ---")
for p in policies:
    print(f"Policy: {p[0]} | Roles: {p[1]} | Cmd: {p[2]} | Qual: {p[3]} | Check: {p[4]}")

# 2. Inspect columns of 'orders' table
cur.execute("SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'orders';")
cols = cur.fetchall()
print("\n--- COLUMNS IN 'orders' TABLE ---")
for c in cols:
    print(f" - {c[0]} ({c[1]}, nullable: {c[2]})")

# 3. Check current orders count in 'orders' table
cur.execute("SELECT COUNT(*) FROM orders;")
order_count = cur.fetchone()[0]
print(f"\nTotal existing orders in 'orders' table: {order_count}")

cur.execute("SELECT id, user_id, customer_name, customer_phone, total_price, status, created_at FROM orders ORDER BY id DESC LIMIT 5;")
latest_orders = cur.fetchall()
print("\n--- LATEST 5 ORDERS IN DATABASE ---")
for o in latest_orders:
    print(f"Order #{o[0]} | UserID: {o[1]} | Name: {o[2]} | Phone: {o[3]} | Total: {o[4]} EGP | Status: {o[5]} | Created: {o[6]}")

cur.close()
conn.close()
