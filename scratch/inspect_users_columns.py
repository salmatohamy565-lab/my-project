import psycopg2

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def main():
    conn = psycopg2.connect(pooler_url)
    cur = conn.cursor()

    cur.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'users';
    """)
    cols = cur.fetchall()
    print("--- PUBLIC.USERS COLUMNS ---")
    for c in cols:
        print(f"Column: {c[0]} | Type: {c[1]} | Nullable: {c[2]}")

    cur.execute("""
        SELECT id, username, role, phone, email
        FROM public.users
        LIMIT 10;
    """)
    users = cur.fetchall()
    print("\n--- SAMPLE USERS ---")
    for u in users:
        print(u)

    cur.close()
    conn.close()

if __name__ == '__main__':
    main()
