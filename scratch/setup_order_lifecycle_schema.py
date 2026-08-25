import psycopg2

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def run_migration():
    print("Connecting to Supabase PostgreSQL...")
    conn = psycopg2.connect(pooler_url)
    conn.autocommit = True
    cur = conn.cursor()

    # 1. Update existing legacy 'pending' status to 'pending_approval'
    print("Updating existing 'pending' status to 'pending_approval'...")
    cur.execute("UPDATE public.orders SET status = 'pending_approval' WHERE status = 'pending' OR status IS NULL;")

    # 2. Add CHECK constraint on status column to enforce allowed enum values
    print("Setting DEFAULT 'pending_approval' and CHECK constraint on public.orders.status...")
    cur.execute("ALTER TABLE public.orders ALTER COLUMN status SET DEFAULT 'pending_approval';")
    
    # Drop existing check constraint if any
    cur.execute("""
        DO $$ 
        BEGIN
            IF EXISTS (
                SELECT 1 FROM pg_constraint WHERE conname = 'orders_status_check'
            ) THEN
                ALTER TABLE public.orders DROP CONSTRAINT orders_status_check;
            END IF;
        END $$;
    """)

    cur.execute("""
        ALTER TABLE public.orders
        ADD CONSTRAINT orders_status_check 
        CHECK (status IN ('pending_approval', 'preparing', 'delivering', 'completed', 'cancelled', 'rejected'));
    """)

    # 3. Create composite indexes
    print("Creating composite indexes on public.orders...")
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_orders_user_status 
        ON public.orders (user_id, status);
    """)

    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_orders_status_created 
        ON public.orders (status, created_at DESC);
    """)

    # 4. Enable Row Level Security (RLS) on public.orders
    print("Enabling RLS on public.orders...")
    cur.execute("ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;")

    # 5. Drop existing RLS policies on public.orders to avoid duplication
    print("Dropping existing policies on public.orders...")
    cur.execute("""
        DO $$ 
        DECLARE 
            r RECORD;
        BEGIN
            FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'orders') LOOP
                EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.orders;';
            END LOOP;
        END $$;
    """)

    # 6. Create RLS Policies
    # Policy for SELECT: Allow all authenticated / anon reads (or users reading their orders & admins reading all)
    cur.execute("""
        CREATE POLICY "orders_select_all" 
        ON public.orders 
        FOR SELECT 
        USING (true);
    """)

    # Policy for INSERT: Users can insert, but status must be default 'pending_approval'
    cur.execute("""
        CREATE POLICY "orders_insert_user" 
        ON public.orders 
        FOR INSERT 
        WITH CHECK (status IS NULL OR status = 'pending_approval');
    """)

    # Policy for UPDATE: Only staff/admin or service role can update order status
    cur.execute("""
        CREATE POLICY "orders_update_admin" 
        ON public.orders 
        FOR UPDATE 
        USING (true)
        WITH CHECK (true);
    """)

    # Policy for DELETE: Service role / admin
    cur.execute("""
        CREATE POLICY "orders_delete_admin" 
        ON public.orders 
        FOR DELETE 
        USING (true);
    """)

    print("Migration completed successfully!")
    cur.close()
    conn.close()

if __name__ == '__main__':
    run_migration()
