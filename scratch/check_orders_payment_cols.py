import psycopg2

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()
cur.execute("SELECT column_name, data_type, character_maximum_length FROM information_schema.columns WHERE table_name='orders' AND column_name LIKE 'payment%';")
print(cur.fetchall())
