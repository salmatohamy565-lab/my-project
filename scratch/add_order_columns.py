import psycopg2

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def main():
    conn = psycopg2.connect(pooler_url)
    cur = conn.cursor()

    cur.execute("""
        ALTER TABLE public.orders 
        ADD COLUMN IF NOT EXISTS payment_proof_url text,
        ADD COLUMN IF NOT EXISTS customer_address text,
        ADD COLUMN IF NOT EXISTS sender_info text,
        ADD COLUMN IF NOT EXISTS notes text;
    """)
    conn.commit()
    print("✓ Successfully added missing columns to public.orders table in Supabase!")

    cur.close()
    conn.close()

if __name__ == '__main__':
    main()
