import psycopg2

conn_str = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(conn_str)
cur = conn.cursor()

cur.execute("SELECT id, user_id, customer_name, customer_phone, status FROM public.orders ORDER BY id DESC;")
rows = cur.fetchall()
print(f"Total orders in Supabase: {len(rows)}")
for r in rows:
    # Print ascii safe
    print(r[0], r[1], repr(r[2]), repr(r[3]), r[4])

cur.close()
conn.close()
