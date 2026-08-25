import psycopg2

direct_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@db.kxeqayzxfvoedqvilcmp.supabase.co:5432/postgres"

try:
    conn = psycopg2.connect(direct_url)
    cur = conn.cursor()
    cur.execute("SELECT 1;")
    print(f"Direct Supabase DB Connection SUCCESS! Result: {cur.fetchone()}")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Direct DB Error: {e}")
