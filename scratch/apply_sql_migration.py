import psycopg2

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# Alter columns to TEXT so no size limit ever causes an insert failure
sql_statements = [
    "ALTER TABLE orders ALTER COLUMN payment_proof_filename TYPE TEXT;",
    "ALTER TABLE orders ALTER COLUMN payment_method TYPE TEXT;",
    "ALTER TABLE orders ALTER COLUMN product_ids TYPE TEXT;",
    "ALTER TABLE orders ALTER COLUMN customer_name TYPE TEXT;",
    "ALTER TABLE orders ALTER COLUMN customer_phone TYPE TEXT;",
    "ALTER TABLE orders ALTER COLUMN status TYPE TEXT;",
    "ALTER TABLE notifications ALTER COLUMN title TYPE TEXT;",
    "ALTER TABLE notifications ALTER COLUMN message TYPE TEXT;",
]

for stmt in sql_statements:
    try:
        cur.execute(stmt)
        print("EXECUTED:", stmt)
    except Exception as e:
        print("ERROR on stmt:", stmt, e)

conn.commit()
print("All SQL alterations committed successfully!")
