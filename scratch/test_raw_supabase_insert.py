import psycopg2

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO orders (customer_name, customer_phone, product_ids, items_summary, total_price, payment_method, status, created_at)
        VALUES ('اختبار طلب جديد', '01234567890', '101', 'مج حراري x1', 150.0, 'instapay', 'pending_approval', NOW())
        RETURNING id;
    """)
    new_id = cur.fetchone()[0]
    conn.commit()
    print("SUCCESS! Inserted Order ID:", new_id)
except Exception as e:
    print("ERROR inserting order:", e)
