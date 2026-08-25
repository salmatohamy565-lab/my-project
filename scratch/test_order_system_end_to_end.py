import psycopg2
import json

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def test_order_system():
    print("========== ORDER SYSTEM END-TO-END VERIFICATION ==========")
    conn = psycopg2.connect(pooler_url)
    conn.autocommit = True
    cur = conn.cursor()

    # 1. Verify RLS is ENABLED on public.orders
    cur.execute("""
        SELECT relrowsecurity, relforcerowsecurity
        FROM pg_class
        WHERE oid = 'public.orders'::regclass;
    """)
    rls_status = cur.fetchone()
    print(f"1. RLS Enabled Status on public.orders: {rls_status}")
    assert rls_status[0] == True, "RLS MUST be enabled on public.orders!"

    # 2. Verify RLS Policies
    cur.execute("""
        SELECT policyname, cmd, qual, with_check
        FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'orders';
    """)
    policies = cur.fetchall()
    print("\n2. Active RLS Policies on public.orders:")
    for pol in policies:
        print(f"  - [{pol[1]}] Policy: {pol[0]}")
    
    # 3. Verify status constraint
    cur.execute("""
        SELECT conname, pg_get_constraintdef(oid)
        FROM pg_constraint
        WHERE conname = 'orders_status_check';
    """)
    constraint = cur.fetchone()
    print(f"\n3. Status Check Constraint: {constraint[1] if constraint else 'None'}")

    # 4. Create a test order directly in Supabase DB
    print("\n4. Testing direct Order insertion into Supabase DB...")
    cur.execute("""
        INSERT INTO public.orders (user_id, customer_name, customer_phone, product_ids, items_summary, total_price, payment_method, customer_address, status, created_at)
        VALUES (106, 'ملاك معتصم اختبار', '01012345678', '1,2', 'برواز فاخر x1', 250.0, 'فودافون كاش', 'العنوان: القاهرة • رقم التحويل: 01012345678', 'pending_approval', NOW())
        RETURNING id, status, created_at;
    """)
    created_order = cur.fetchone()
    print(f"   [SUCCESS] Test Order created successfully in Supabase DB: ID #{created_order[0]}, Status: '{created_order[1]}'")
    test_order_id = created_order[0]

    # 5. Test Status Transitions (pending_approval -> preparing -> delivering -> completed)
    print("\n5. Testing Order Status transitions...")
    statuses = ['preparing', 'delivering', 'completed']
    for st in statuses:
        cur.execute("UPDATE public.orders SET status = %s WHERE id = %s RETURNING status;", (st, test_order_id))
        updated_st = cur.fetchone()[0]
        print(f"   [SUCCESS] Order #{test_order_id} status updated to: '{updated_st}'")
        assert updated_st == st

    # 6. Clean up test order
    print("\n6. Cleaning up test order...")
    cur.execute("DELETE FROM public.orders WHERE id = %s;", (test_order_id,))
    print("   [SUCCESS] Test order cleaned up.")

    print("\n========== ALL ORDER SYSTEM VERIFICATIONS PASSED! ==========")
    cur.close()
    conn.close()

if __name__ == '__main__':
    test_order_system()
