import psycopg2

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def main():
    conn = psycopg2.connect(pooler_url)
    cur = conn.cursor()

    sample_proof_url = "https://kxeqayzxfvoedqvilcmp.supabase.co/storage/v1/object/public/payment-proofs/sample_receipt.jpg"

    cur.execute("""
        UPDATE public.orders
        SET payment_proof_url = %s, payment_proof_filename = %s
        WHERE id = 123 OR status = 'pending_approval';
    """, (sample_proof_url, sample_proof_url))
    conn.commit()
    print("Updated pending orders with test proof url!")

    cur.close()
    conn.close()

if __name__ == '__main__':
    main()
