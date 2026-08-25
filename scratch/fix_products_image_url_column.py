import psycopg2

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def fix_products_table():
    print("Connecting to Supabase Database...")
    conn = psycopg2.connect(pooler_url)
    conn.autocommit = True
    cur = conn.cursor()

    print("Adding image_url column to public.products if missing...")
    cur.execute("""
        ALTER TABLE public.products ADD COLUMN IF NOT EXISTS image_url text;
    """)

    print("Copying image_filename to image_url where image_url is null...")
    cur.execute("""
        UPDATE public.products SET image_url = image_filename WHERE image_url IS NULL AND image_filename IS NOT NULL;
    """)

    print("Notifying PostgREST to reload schema cache...")
    cur.execute("NOTIFY pgrst, 'reload schema';")

    print("Verifying products table columns...")
    cur.execute("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'products';
    """)
    cols = cur.fetchall()
    for col in cols:
        print(" -", col)

    cur.close()
    conn.close()
    print("Done successfully!")

if __name__ == '__main__':
    fix_products_table()
