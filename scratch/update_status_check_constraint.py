import psycopg2

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def update_constraint():
    conn = psycopg2.connect(pooler_url)
    conn.autocommit = True
    cur = conn.cursor()

    print("Updating orders_status_check constraint to support ready, delivering, completed, delivered...")
    cur.execute("""
        ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
    """)

    cur.execute("""
        ALTER TABLE public.orders
        ADD CONSTRAINT orders_status_check 
        CHECK (status IN ('pending_approval', 'pending', 'preparing', 'delivering', 'ready', 'completed', 'delivered', 'cancelled', 'rejected'));
    """)

    print("[OK] Successfully updated orders_status_check constraint!")
    cur.close()
    conn.close()

if __name__ == '__main__':
    update_constraint()
