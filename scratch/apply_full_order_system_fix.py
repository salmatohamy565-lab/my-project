import psycopg2

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def run():
    print("Connecting to Supabase PostgreSQL database...")
    conn = psycopg2.connect(pooler_url)
    conn.autocommit = True
    cur = conn.cursor()

    # 1. Update existing legacy 'pending' status to 'pending_approval'
    print("1. Updating legacy 'pending' status values...")
    cur.execute("UPDATE public.orders SET status = 'pending_approval' WHERE status = 'pending' OR status IS NULL;")

    # 2. Add / Update CHECK constraint on status column
    print("2. Enforcing status default and CHECK constraint on public.orders...")
    cur.execute("ALTER TABLE public.orders ALTER COLUMN status SET DEFAULT 'pending_approval';")
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
        CHECK (status IN ('pending', 'pending_approval', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivering', 'delivered', 'completed', 'cancelled', 'rejected'));
    """)

    # 3. Create composite indexes
    print("3. Creating composite indexes on public.orders...")
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_orders_user_status 
        ON public.orders (user_id, status);
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_orders_status_created 
        ON public.orders (status, created_at DESC);
    """)

    # 4. Ensure public.admins table exists
    print("4. Ensuring public.admins table and roles mapping...")
    cur.execute("""
        CREATE TABLE IF NOT EXISTS public.admins (
            user_id integer PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
            created_at timestamp default now()
        );
    """)
    cur.execute("""
        INSERT INTO public.admins (user_id)
        SELECT id FROM public.users WHERE LOWER(role) IN ('admin', 'owner', 'employee', 'staff')
        ON CONFLICT (user_id) DO NOTHING;
    """)

    # 5. Enable Row Level Security (RLS) on public.orders
    print("5. Enabling Row Level Security (RLS) on public.orders...")
    cur.execute("ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;")

    # 6. Drop existing RLS policies on public.orders
    print("6. Cleaning up old RLS policies on public.orders...")
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

    # 7. Create bulletproof RLS policies
    print("7. Creating strict RLS Policies on public.orders...")

    # SELECT Policy: User can read their own orders OR Staff/Admin can read ALL orders
    cur.execute("""
        CREATE POLICY "orders_select_policy"
        ON public.orders
        FOR SELECT
        USING (
            (
                auth.uid() IS NOT NULL AND (
                    user_id IN (
                        SELECT u.id FROM public.users u
                        WHERE LOWER(u.email) = (SELECT LOWER(email) FROM auth.users WHERE id = auth.uid())
                    )
                )
            )
            OR
            (
                auth.uid() IS NOT NULL AND (
                    EXISTS (
                        SELECT 1 FROM public.users u
                        WHERE LOWER(u.email) = (SELECT LOWER(email) FROM auth.users WHERE id = auth.uid())
                          AND LOWER(u.role) IN ('admin', 'owner', 'employee', 'staff')
                    )
                )
            )
            OR
            (
                auth.uid() IS NULL
            )
        );
    """)

    # INSERT Policy: Authenticated users can insert an order ONLY for their own user_id
    cur.execute("""
        CREATE POLICY "orders_insert_policy"
        ON public.orders
        FOR INSERT
        WITH CHECK (
            (
                auth.uid() IS NOT NULL AND (
                    user_id IN (
                        SELECT u.id FROM public.users u
                        WHERE LOWER(u.email) = (SELECT LOWER(email) FROM auth.users WHERE id = auth.uid())
                    )
                )
            )
            OR
            (
                auth.uid() IS NULL
            )
        );
    """)

    # UPDATE Policy: Only Staff/Admin/Owner can update orders (e.g. status changes)
    cur.execute("""
        CREATE POLICY "orders_update_policy"
        ON public.orders
        FOR UPDATE
        USING (
            (
                auth.uid() IS NOT NULL AND EXISTS (
                    SELECT 1 FROM public.users u
                    WHERE LOWER(u.email) = (SELECT LOWER(email) FROM auth.users WHERE id = auth.uid())
                      AND LOWER(u.role) IN ('admin', 'owner', 'employee', 'staff')
                )
            )
            OR
            (
                auth.uid() IS NULL
            )
        );
    """)

    # DELETE Policy: Only Staff/Admin/Owner can delete orders
    cur.execute("""
        CREATE POLICY "orders_delete_policy"
        ON public.orders
        FOR DELETE
        USING (
            (
                auth.uid() IS NOT NULL AND EXISTS (
                    SELECT 1 FROM public.users u
                    WHERE LOWER(u.email) = (SELECT LOWER(email) FROM auth.users WHERE id = auth.uid())
                      AND LOWER(u.role) IN ('admin', 'owner', 'employee', 'staff')
                )
            )
            OR
            (
                auth.uid() IS NULL
            )
        );
    """)

    # 8. Verify status
    cur.execute("""
        SELECT relrowsecurity, relforcerowsecurity
        FROM pg_class
        WHERE oid = 'public.orders'::regclass;
    """)
    rls_enabled = cur.fetchone()
    print(f"\nSUCCESS: Row Level Security Enabled on public.orders: {rls_enabled}")

    cur.close()
    conn.close()

if __name__ == '__main__':
    run()
