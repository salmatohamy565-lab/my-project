import psycopg2
import sys

sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def test_order_flow():
    print("Connecting to Supabase Database...")
    conn = psycopg2.connect(pooler_url)
    conn.autocommit = True
    cur = conn.cursor()

    cur.execute("SELECT id FROM public.users LIMIT 1;")
    user_row = cur.fetchone()
    user_id = user_row[0] if user_row else None
    print(f"Using test user_id: {user_id}")

    print("\n--- TEST 1: Insert Order Without 'status' (Default DB Behavior) ---")
    cur.execute("""
        INSERT INTO public.orders (user_id, customer_name, customer_phone, items_summary, total_price, payment_method, created_at)
        VALUES (%s, 'اختبار التدفق التلقائي', '01000000000', 'قميص رجالي - 1', 250.0, 'instapay', NOW())
        RETURNING id, status;
    """, (user_id,))
    order_id, default_status = cur.fetchone()
    print(f"[OK] Created test order #{order_id} with DEFAULT status: '{default_status}'")
    assert default_status == 'pending_approval', f"Expected 'pending_approval' but got '{default_status}'"

    print("\n--- TEST 2: Admin Accepts Order -> Update status to 'preparing' ---")
    cur.execute("""
        UPDATE public.orders
        SET status = 'preparing'
        WHERE id = %s
        RETURNING id, status;
    """, (order_id,))
    updated_id, new_status = cur.fetchone()
    print(f"[OK] Updated order #{updated_id} status to: '{new_status}'")
    assert new_status == 'preparing', f"Expected 'preparing' but got '{new_status}'"

    print("\n--- TEST 3: Admin Rejects Order -> Update status to 'rejected' ---")
    cur.execute("""
        UPDATE public.orders
        SET status = 'rejected', rejection_reason = 'اختبار الرفض تلقائيا'
        WHERE id = %s
        RETURNING id, status, rejection_reason;
    """, (order_id,))
    rejected_id, rej_status, reason = cur.fetchone()
    print(f"[OK] Updated order #{rejected_id} status to: '{rej_status}' with reason: '{reason}'")
    assert rej_status == 'rejected', f"Expected 'rejected' but got '{rej_status}'"

    print("\n--- TEST 4: Cleanup Test Order ---")
    cur.execute("DELETE FROM public.orders WHERE id = %s;", (order_id,))
    print(f"[OK] Cleaned up test order #{order_id}")

    print("\nALL LIFECYCLE TESTS PASSED SUCCESSFULLY!")
    cur.close()
    conn.close()

if __name__ == '__main__':
    test_order_flow()
