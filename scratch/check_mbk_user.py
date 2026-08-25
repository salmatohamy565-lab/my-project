import psycopg2
import json

conn_str = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(conn_str)
cur = conn.cursor()

cur.execute("SELECT id, username, email, phone, role FROM public.users WHERE username LIKE '%مبك%' OR email LIKE '%مبك%';")
rows = cur.fetchall()

result = []
for r in rows:
    result.append({"id": r[0], "username": r[1], "email": r[2], "phone": r[3], "role": r[4]})

with open("scratch/mbk_users.json", "w", encoding="utf-8") as f:
    json.dump(result, f, ensure_ascii=False, indent=2)

print("Exported", len(result), "mbk users to scratch/mbk_users.json")

cur.close()
conn.close()
