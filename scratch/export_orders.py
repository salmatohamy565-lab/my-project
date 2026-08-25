import psycopg2
import json

conn_str = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(conn_str)
cur = conn.cursor()

cur.execute("SELECT id, user_id, customer_name, customer_phone, total_price, status FROM public.orders ORDER BY id DESC;")
orders = cur.fetchall()

result = []
for o in orders:
    result.append({
        "id": o[0],
        "user_id": o[1],
        "customer_name": o[2],
        "customer_phone": o[3],
        "total_price": o[4],
        "status": o[5]
    })

with open("scratch/supabase_orders.json", "w", encoding="utf-8") as f:
    json.dump(result, f, ensure_ascii=False, indent=2)

print("Saved", len(result), "orders to scratch/supabase_orders.json")

cur.close()
conn.close()
