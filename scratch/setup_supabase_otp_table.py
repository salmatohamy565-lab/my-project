import psycopg2
import sys

sys.stdout.reconfigure(encoding='utf-8')
db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    # Create otp_codes table in Supabase Database if not exists
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS otp_codes (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) NOT NULL,
        code VARCHAR(10) NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
        is_used BOOLEAN DEFAULT FALSE
    );
    """
    cur.execute(create_table_sql)
    conn.commit()
    print("[SUPABASE OTP TABLE] Successfully ensured 'otp_codes' table exists in Supabase DB!")

    cur.close()
    conn.close()
except Exception as e:
    print(f"[SUPABASE OTP TABLE ERROR] {e}")
