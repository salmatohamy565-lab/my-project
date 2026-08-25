import psycopg2
import sys

sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def fix_products_db():
    print("Connecting to Supabase Database...")
    conn = psycopg2.connect(pooler_url)
    conn.autocommit = True
    cur = conn.cursor()

    print("\n--- 1. Reset products_id_seq to MAX(id) + 1 ---")
    cur.execute("""
        SELECT setval('public.products_id_seq', COALESCE((SELECT MAX(id) FROM public.products), 0) + 1, false);
    """)
    next_val = cur.fetchone()
    print(f"[OK] Reset products_id_seq. Next ID will be: {next_val[0]}")

    print("\n--- 2. Grant table & sequence permissions ---")
    cur.execute("""
        GRANT ALL ON TABLE public.products TO anon, authenticated, service_role;
        GRANT USAGE, SELECT ON SEQUENCE public.products_id_seq TO anon, authenticated, service_role;
    """)
    print("[OK] Granted permissions on public.products table & sequence!")

    print("\n--- 3. Configure RLS & Policies on public.products ---")
    cur.execute("ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;")
    
    cur.execute("""
        DO $$ 
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_policies WHERE policyname = 'products_all_access'
            ) THEN
                CREATE POLICY "products_all_access" ON public.products
                FOR ALL USING (true) WITH CHECK (true);
            END IF;
        END $$;
    """)
    print("[OK] Configured RLS policy 'products_all_access' on public.products!")

    print("\nALL DATABASE PRODUCT FIXES COMPLETED SUCCESSFULLY!")
    cur.close()
    conn.close()

if __name__ == '__main__':
    fix_products_db()
