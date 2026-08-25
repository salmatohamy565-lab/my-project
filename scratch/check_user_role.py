import psycopg2

conn_str = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(conn_str)
cur = conn.cursor()

cur.execute("SELECT id, username, email, phone, role FROM public.users ORDER BY id DESC LIMIT 10;")
rows = cur.fetchall()
print("Top 10 Users in Supabase:")
for r in rows:
    print(f"ID: {r[0]}, Username: {repr(r[1])}, Email: {repr(r[2])}, Role: {repr(r[4])}")

cur.close()
conn.close()
