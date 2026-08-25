import psycopg2

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def main():
    conn = psycopg2.connect(pooler_url)
    cur = conn.cursor()

    cur.execute("""
        SELECT tablename, policyname, roles, cmd, qual, with_check
        FROM pg_policies
        WHERE schemaname = 'public';
    """)
    policies = cur.fetchall()
    print("--- ACTIVE RLS POLICIES IN PUBLIC SCHEMA ---")
    for p in policies:
        print(f"Table: {p[0]} | Policy: {p[1]} | Roles: {p[2]} | Cmd: {p[3]}")
        print(f"  USING: {p[4]}")
        print(f"  WITH CHECK: {p[5]}")
        print("-" * 50)

    cur.close()
    conn.close()

if __name__ == '__main__':
    main()
