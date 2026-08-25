import psycopg2

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def main():
    conn = psycopg2.connect(pooler_url)
    cur = conn.cursor()
    cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='public';")
    tables = cur.fetchall()
    print("Tables:", [t[0] for t in tables])
    
    for t in ['categories', 'subcategories', 'products']:
        cur.execute(f"SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema='public' AND table_name='{t}';")
        cols = cur.fetchall()
        print(f"\n--- {t.upper()} ---")
        for col in cols:
            print(col)
            
    cur.close()
    conn.close()

if __name__ == '__main__':
    main()
