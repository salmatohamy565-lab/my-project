import psycopg2

conn_str = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(conn_str)
    cur = conn.cursor()

    cur.execute("""
        INSERT INTO public.orders 
        (user_id, customer_name, customer_phone, product_ids, items_summary, payment_method, total_price, status, created_at)
        VALUES (173, 'مبك معتصم راضي', '01277722869', '1,2', 'منتج اختبار', 'كاش', 150.0, 'pending_approval', NOW())
        RETURNING id;
    """)
    new_id = cur.fetchone()[0]
    conn.commit()
    print("SUCCESSFULLY INSERTED ORDER IN SUPABASE! ID =", new_id)

    cur.close()
    conn.close()
except Exception as e:
    print("INSERT ERROR:", e)
