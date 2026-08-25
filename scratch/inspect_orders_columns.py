import psycopg2
import sys

sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def main():
    conn = psycopg2.connect(pooler_url)
    cur = conn.cursor()

    cur.execute("""
        SELECT id, customer_name, customer_phone, items_summary, total_price, payment_method, payment_proof_filename, status, created_at
        FROM public.orders
        ORDER BY id DESC
        LIMIT 10;
    """)
    rows = cur.fetchall()
    print("--- RECENT ORDERS IN SUPABASE ---")
    for r in rows:
        print(f"Order #{r[0]} | Name: {r[1]} | Phone: {r[2]} | Items: {r[3]} | Price: {r[4]} | Method: {r[5]} | ProofCol: {r[6]} | Status: {r[7]} | Date: {r[8]}")

    cur.close()
    conn.close()

if __name__ == '__main__':
    main()
