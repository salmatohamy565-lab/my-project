import psycopg2

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def run():
    conn = psycopg2.connect(pooler_url)
    conn.autocommit = True
    cur = conn.cursor()

    print("1. Creating public.admins table if not exists...")
    cur.execute("""
        CREATE TABLE IF NOT EXISTS public.admins (
            user_id integer PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
            created_at timestamp default now()
        );
    """)

    print("2. Populating public.admins with users having role IN ('admin', 'employee')...")
    cur.execute("""
        INSERT INTO public.admins (user_id)
        SELECT id FROM public.users WHERE LOWER(role) IN ('admin', 'employee', 'staff')
        ON CONFLICT (user_id) DO NOTHING;
    """)

    print("3. Enabling RLS on public.orders...")
    cur.execute("ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;")

    print("4. Dropping existing RLS policies on public.orders...")
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

    print("5. Creating strict RLS policies on public.orders...")
    
    # SELECT Policy: User can read their own orders OR staff/admin can read all orders
    cur.execute("""
        CREATE POLICY "orders_select_policy"
        ON public.orders
        FOR SELECT
        USING (
            (
                auth.uid() IS NOT NULL AND (
                    user_id IN (
                        SELECT u.id FROM public.users u
                        WHERE u.email = (SELECT email FROM auth.users WHERE id = auth.uid())
                    )
                )
            )
            OR
            (
                auth.uid() IS NOT NULL AND (
                    EXISTS (
                        SELECT 1 FROM public.admins a
                        JOIN public.users u ON u.id = a.user_id
                        WHERE u.email = (SELECT email FROM auth.users WHERE id = auth.uid())
                    )
                )
            )
        );
    """)

    # INSERT Policy: Authenticated users can insert pending orders
    cur.execute("""
        CREATE POLICY "orders_insert_policy"
        ON public.orders
        FOR INSERT
        WITH CHECK (
            (status IS NULL OR status = 'pending_approval' OR status = 'pending')
        );
    """)

    # UPDATE Policy: Only staff/admin can update orders
    cur.execute("""
        CREATE POLICY "orders_update_policy"
        ON public.orders
        FOR UPDATE
        USING (
            auth.uid() IS NOT NULL AND EXISTS (
                SELECT 1 FROM public.admins a
                JOIN public.users u ON u.id = a.user_id
                WHERE u.email = (SELECT email FROM auth.users WHERE id = auth.uid())
            )
        );
    """)

    # DELETE Policy: Only staff/admin can delete orders
    cur.execute("""
        CREATE POLICY "orders_delete_policy"
        ON public.orders
        FOR DELETE
        USING (
            auth.uid() IS NOT NULL AND EXISTS (
                SELECT 1 FROM public.admins a
                JOIN public.users u ON u.id = a.user_id
                WHERE u.email = (SELECT email FROM auth.users WHERE id = auth.uid())
            )
        );
    """)

    print("RLS hardening completed successfully!")
    cur.close()
    conn.close()

if __name__ == '__main__':
    run()
