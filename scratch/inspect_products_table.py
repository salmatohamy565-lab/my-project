import psycopg2

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def inspect_products():
    print("Connecting to Supabase Database...")
    conn = psycopg2.connect(pooler_url)
    cur = conn.cursor()

    cur.execute("""
        SELECT column_name, data_type, column_default, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'products';
    """)
    cols = cur.fetchall()
    print("--- PRODUCTS COLUMNS ---")
    for col in cols:
        print(col)

    cur.execute("SELECT COUNT(*) FROM public.products;")
    count = cur.fetchone()[0]
    print(f"Total Products in Supabase: {count}")

    cur.close()
    conn.close()

if __name__ == '__main__':
    inspect_products()
