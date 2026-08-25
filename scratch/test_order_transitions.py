import psycopg2
import sys

sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def test_transitions():
    conn = psycopg2.connect(pooler_url)
    conn.autocommit = True
    cur = conn.cursor()

    cur.execute("SELECT id FROM public.users LIMIT 1;")
    user_id = cur.fetchone()[0]

    print("\n--- TEST: Order Transitions Cycle ---")
    # 1. Create order
    cur.execute("""
        INSERT INTO public.orders (user_id, customer_name, customer_phone, items_summary, total_price, payment_method, created_at)
        VALUES (%s, 'عميل تجريبي للتحكم', '01000000000', 'منتج اختبار التنقل', 150.0, 'instapay', NOW())
        RETURNING id, status;
    """, (user_id,))
    oid, st1 = cur.fetchone()
    print(f"[OK] 1. New Order #{oid} -> Status: '{st1}' (tab 0: بانتظار الموافقة)")
    assert st1 == 'pending_approval'

    # 2. Accept (preparing)
    cur.execute("UPDATE public.orders SET status = 'preparing' WHERE id = %s RETURNING status;", (oid,))
    st2 = cur.fetchone()[0]
    print(f"[OK] 2. Accepted Order #{oid} -> Status: '{st2}' (tab 1: قيد التجهيز)")
    assert st2 == 'preparing'

    # 3. Ready for delivery (ready)
    cur.execute("UPDATE public.orders SET status = 'ready' WHERE id = %s RETURNING status;", (oid,))
    st3 = cur.fetchone()[0]
    print(f"[OK] 3. Ready Order #{oid} -> Status: '{st3}' (tab 2: جاهز وتوصيل)")
    assert st3 == 'ready'

    # 4. Delivered (delivered)
    cur.execute("UPDATE public.orders SET status = 'delivered' WHERE id = %s RETURNING status;", (oid,))
    st4 = cur.fetchone()[0]
    print(f"[OK] 4. Delivered Order #{oid} -> Status: '{st4}' (tab 3: تم التسليم)")
    assert st4 == 'delivered'

    # Clean up
    cur.execute("DELETE FROM public.orders WHERE id = %s;", (oid,))
    print(f"[OK] Cleaned up test order #{oid}")

    print("\nALL ORDER TRANSITIONS PASSED SUCCESSFULLY!")
    cur.close()
    conn.close()

if __name__ == '__main__':
    test_transitions()
