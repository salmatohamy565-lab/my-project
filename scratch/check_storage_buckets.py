import psycopg2

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# Create storage buckets in Supabase for payment proofs
sql_statements = [
    "INSERT INTO storage.buckets (id, name, public) VALUES ('payment-proofs', 'payment-proofs', true) ON CONFLICT (id) DO UPDATE SET public = true;",
    "INSERT INTO storage.buckets (id, name, public) VALUES ('payment_proofs', 'payment_proofs', true) ON CONFLICT (id) DO UPDATE SET public = true;",
]

for stmt in sql_statements:
    try:
        cur.execute(stmt)
        print("EXECUTED BUCKET CREATION:", stmt)
    except Exception as e:
        print("ERROR:", stmt, e)

conn.commit()

# Verify buckets
cur.execute("SELECT id, name, public FROM storage.buckets;")
print("ALL BUCKETS NOW IN SUPABASE STORAGE:", cur.fetchall())
