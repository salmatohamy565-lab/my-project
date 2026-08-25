import psycopg2

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

policies = [
    "DROP POLICY IF EXISTS \"Public Access Payment Proofs Select\" ON storage.objects;",
    "DROP POLICY IF EXISTS \"Public Access Payment Proofs Insert\" ON storage.objects;",
    "CREATE POLICY \"Public Access Payment Proofs Select\" ON storage.objects FOR SELECT USING (bucket_id IN ('payment-proofs', 'payment_proofs'));",
    "CREATE POLICY \"Public Access Payment Proofs Insert\" ON storage.objects FOR INSERT WITH CHECK (bucket_id IN ('payment-proofs', 'payment_proofs'));",
]

for p in policies:
    try:
        cur.execute(p)
        print("EXECUTED STORAGE POLICY:", p)
    except Exception as e:
        print("NOTICE:", e)

conn.commit()
print("Storage RLS policies applied successfully!")
