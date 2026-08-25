import psycopg2
import json

conn_str = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(conn_str)
cur = conn.cursor()

cur.execute("SELECT id, username, email, phone, role FROM public.users ORDER BY id DESC;")
rows = cur.fetchall()
print(f"Total users: {len(rows)}")
for r in rows:
    print(dict(id=r[0], username=r[1], email=r[2], phone=r[3], role=r[4]))

print("\n--- ALL ORDERS IN SUPABASE ---")
cur.execute("SELECT id, user_id, customer_name, customer_phone, total_price, status FROM public.orders ORDER BY id DESC;")
orders = cur.fetchall()
print(f"Total orders: {len(orders)}")
for o in orders:
    print(dict(id=o[0], user_id=o[1], name=o[2], phone=o[3], price=o[4], status=o[5]))

cur.close()
conn.close()
