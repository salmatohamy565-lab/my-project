import psycopg2

conn_str = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(conn_str)
cur = conn.cursor()

cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'users';")
cols = [c[0] for c in cur.fetchall()]
print("Users table columns:", cols)

cur.execute("SELECT * FROM public.users LIMIT 10;")
rows = cur.fetchall()
for r in rows:
    print(r)

cur.close()
conn.close()
