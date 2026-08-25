import psycopg2
import sys
from datetime import datetime

sys.stdout.reconfigure(encoding='utf-8')
db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

marketing_messages = [
    ("🖤 عرض خاص لفترة محدودة", "متنسيش تطلب برواز صورتك النهاردة 🖤 عرض خاص لفترة محدودة"),
    ("✨ فاجئي أولادك ببرواز مميز", "فاجئي أولادك ببرواز مميز يليق باللحظات الغالية ✨"),
    ("✨ برواز فاخر بلمسة ذهبية", "برواز فاخر بلمسة ذهبية... اطلبيه دلوقتي قبل ما العرض يخلص"),
    ("🖼️ ذكريات تدوم للأبد", "متبقاش الذكريات مجرد صور... حوّليها لبرواز يدوم")
]

try:
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()
    
    # Get user 2 (Bola) or first available user
    cur.execute("SELECT id, username, email FROM users LIMIT 1;")
    user = cur.fetchone()
    if user:
        user_id = user[0]
        # Insert test marketing notification
        title, msg = marketing_messages[0]
        cur.execute(
            "INSERT INTO notifications (user_id, title, message, is_read, created_at) VALUES (%s, %s, %s, %s, %s) RETURNING id;",
            (user_id, title, msg, False, datetime.now())
        )
        notif_id = cur.fetchone()[0]
        conn.commit()
        print(f"Successfully inserted Marketing Notification ID: {notif_id} for user_id: {user_id} ({user[1]} / {user[2]})")
        
        # Count unread notifications
        cur.execute("SELECT COUNT(*) FROM notifications WHERE user_id = %s AND is_read = false;", (user_id,))
        unread_count = cur.fetchone()[0]
        print(f"Current Unread Notification Badge Count for User {user_id} in Supabase DB (notifications table): {unread_count}")
        
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error testing notification insertion: {e}")
