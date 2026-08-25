import psycopg2

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# Drop foreign key constraints on notifications.user_id
cur.execute("""
    ALTER TABLE notifications DROP CONSTRAINT IF EXISTS fk_notifications_user_id_users;
    ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
    ALTER TABLE notifications ALTER COLUMN user_id DROP NOT NULL;
""")

conn.commit()
print("Successfully dropped user_id foreign key constraint on notifications table!")
