import psycopg2
import json

direct_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(direct_url)
    cur = conn.cursor()
    
    # 1. Get columns of public.orders
    cur.execute("""
        SELECT column_name, data_type, udt_name, column_default, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'orders';
    """)
    columns = cur.fetchall()
    print("--- ORDERS COLUMNS ---")
    for col in columns:
        print(col)
        
    # 2. Get enum values if order_status enum exists
    cur.execute("""
        SELECT t.typname, e.enumlabel
        FROM pg_type t
        JOIN pg_enum e ON t.oid = e.enumtypid
        WHERE t.typname LIKE '%status%' OR t.typname LIKE '%order%';
    """)
    enums = cur.fetchall()
    print("\n--- ENUM LABELS ---")
    print(enums)

    # 3. Get indexes on public.orders
    cur.execute("""
        SELECT indexname, indexdef
        FROM pg_indexes
        WHERE schemaname = 'public' AND tablename = 'orders';
    """)
    indexes = cur.fetchall()
    print("\n--- INDEXES ---")
    for idx in indexes:
        print(idx)

    # 4. Get RLS policies on public.orders
    cur.execute("""
        SELECT policyname, permissive, roles, cmd, qual, with_check
        FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'orders';
    """)
    policies = cur.fetchall()
    print("\n--- RLS POLICIES ---")
    for pol in policies:
        print(pol)

    # 5. Check if RLS is enabled on public.orders
    cur.execute("""
        SELECT relrowsecurity, relforcerowsecurity
        FROM pg_class
        WHERE oid = 'public.orders'::regclass;
    """)
    rls_status = cur.fetchone()
    print("\n--- RLS STATUS ---")
    print(f"Row Level Security Enabled: {rls_status}")

    cur.close()
    conn.close()
except Exception as e:
    print(f"DB Error: {e}")
