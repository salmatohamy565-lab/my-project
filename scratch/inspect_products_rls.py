import psycopg2

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def check_products_rls():
    conn = psycopg2.connect(pooler_url)
    cur = conn.cursor()

    cur.execute("""
        SELECT relrowsecurity, relforcerowsecurity
        FROM pg_class
        WHERE oid = 'public.products'::regclass;
    """)
    rls_status = cur.fetchone()
    print("--- PRODUCTS RLS STATUS ---")
    print(f"Row Level Security Enabled: {rls_status}")

    cur.execute("""
        SELECT policyname, permissive, roles, cmd, qual, with_check
        FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'products';
    """)
    policies = cur.fetchall()
    print("\n--- PRODUCTS RLS POLICIES ---")
    for pol in policies:
        print(pol)

    cur.close()
    conn.close()

if __name__ == '__main__':
    check_products_rls()
