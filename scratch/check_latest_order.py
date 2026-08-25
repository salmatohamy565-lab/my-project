import psycopg2
import json

conn_str = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(conn_str)
cur = conn.cursor()

cur.execute("SELECT id, user_id, customer_name, customer_phone, total_price, status, created_at FROM public.orders ORDER BY id DESC;")
rows = cur.fetchall()

result = []
for r in rows:
    result.append({
        "id": r[0],
        "user_id": r[1],
        "customer_name": r[2],
        "customer_phone": r[3],
        "total_price": r[4],
        "status": r[5],
        "created_at": str(r[6])
    })

with open("scratch/latest_supabase_orders.json", "w", encoding="utf-8") as f:
    json.dump(result, f, ensure_ascii=False, indent=2)

print("Total orders in Supabase right now:", len(result))

cur.close()
conn.close()
