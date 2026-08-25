import psycopg2
import datetime

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

cur.execute("""
    INSERT INTO orders (
        customer_name, customer_phone, product_ids, items_summary, payment_method, 
        total_price, status, sender_info, customer_address, notes, payment_proof_url, payment_proof_filename, created_at
    ) VALUES (
        'اختبار عميل تجريبي', '01012345678', '101,102', 'مج حراري x1 • سلسلة خشبية x1', 'فودافون كاش',
        250.0, 'pending_approval', 'العنوان: القاهرة • رقم التحويل: 01012345678', 'القاهرة', 'العنوان: القاهرة • رقم التحويل: 01012345678',
        'http://example.com/proof.jpg', 'proof_123.jpg', NOW()
    ) RETURNING id;
""")

new_id = cur.fetchone()[0]

# Also insert notification for admin and user
cur.execute("""
    INSERT INTO notifications (order_id, user_id, title, message, is_read, created_at)
    VALUES (%s, 0, %s, %s, false, NOW());
""", (new_id, f'📢 طلب جديد #{new_id}', 'وصل طلب جديد بقيمة 250 ج.م'))

conn.commit()

print(f"SUCCESS! Created Order #{new_id} and notification in Supabase!")
