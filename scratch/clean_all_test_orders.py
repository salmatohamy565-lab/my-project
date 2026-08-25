import psycopg2

conn_str = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

print("Connecting to Supabase Postgres database...")
conn = psycopg2.connect(conn_str)
cur = conn.cursor()

# Wipe all test orders from Supabase orders table
cur.execute("DELETE FROM public.orders;")
conn.commit()
print("Wiped all old test orders from Supabase public.orders table!")

cur.execute("SELECT COUNT(*) FROM public.orders;")
count = cur.fetchone()[0]
print(f"Current remaining orders in Supabase: {count}")

cur.close()
conn.close()
