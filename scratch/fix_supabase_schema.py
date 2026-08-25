import psycopg2

conn_str = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

print("Connecting to Supabase Postgres database...")
conn = psycopg2.connect(conn_str)
cur = conn.cursor()

sqls = [
    "ALTER TABLE public.orders ALTER COLUMN user_id DROP NOT NULL;",
    "ALTER TABLE public.orders ALTER COLUMN user_id SET DEFAULT 0;",
    "ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;",
    "GRANT ALL ON public.orders TO anon;",
    "GRANT ALL ON public.orders TO authenticated;",
    "GRANT ALL ON public.orders TO service_role;"
]

for sql in sqls:
    try:
        cur.execute(sql)
        conn.commit()
        print(f"EXECUTED SUCCESS: {sql}")
    except Exception as err:
        conn.rollback()
        print(f"SQL EXCEPTION on [{sql}]: {err}")

cur.close()
conn.close()
