import psycopg2

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def main():
    conn = psycopg2.connect(pooler_url)
    cur = conn.cursor()

    cur.execute("""
        SELECT id, email, phone, raw_user_meta_data
        FROM auth.users
        LIMIT 10;
    """)
    users = cur.fetchall()
    print("--- AUTH.USERS ---")
    for u in users:
        print(u)

    cur.close()
    conn.close()

if __name__ == '__main__':
    main()
