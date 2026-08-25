import psycopg2

conn_str = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

print("Connecting to Supabase Postgres to clean up test/unrelated orders...")
conn = psycopg2.connect(conn_str)
cur = conn.cursor()

# Delete test orders with customer_name 'Test User' or 'اختبار' or dummy items
cur.execute("DELETE FROM public.orders WHERE customer_name LIKE '%Test%' OR customer_name LIKE '%اختبار%' OR customer_name IS NULL OR customer_name = '';")
conn.commit()

print(f"Deleted test orders. Remaining count: {cur.rowcount}")

cur.execute("SELECT id, customer_name, customer_phone, total_price, status, created_at FROM public.orders ORDER BY id DESC LIMIT 20;")
rows = cur.fetchall()
print("Remaining orders in Supabase:")
for r in rows:
    print(r)

cur.close()
conn.close()
