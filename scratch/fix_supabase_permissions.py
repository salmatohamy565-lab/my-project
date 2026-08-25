import psycopg2

conn_str = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

print("Connecting to Supabase Postgres database...")
try:
    conn = psycopg2.connect(conn_str)
    print("Successfully connected!")
    cur = conn.cursor()
    
    # 1. Disable RLS on orders table and grant full access to anon and authenticated roles
    sqls = [
        "ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;",
        "GRANT ALL ON public.orders TO anon;",
        "GRANT ALL ON public.orders TO authenticated;",
        "GRANT ALL ON public.orders TO service_role;",
        "GRANT USAGE ON SCHEMA public TO anon;",
        "GRANT USAGE ON SCHEMA public TO authenticated;",
        "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;",
        "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;",
        "GRANT SELECT ON auth.users TO anon;",
        "GRANT SELECT ON auth.users TO authenticated;"
    ]
    
    for sql in sqls:
        try:
            cur.execute(sql)
            conn.commit()
            print(f"EXECUTED SUCCESS: {sql}")
        except Exception as err:
            conn.rollback()
            print(f"SQL EXCEPTION on [{sql}]: {err}")
            
    # Check orders table schema
    cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'orders';")
    cols = cur.fetchall()
    print("Orders table columns:", cols)
    
    cur.close()
    conn.close()

except Exception as e:
    print("Connection Error:", e)
