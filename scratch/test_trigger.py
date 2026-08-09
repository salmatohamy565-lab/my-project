import psycopg2

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
conn = psycopg2.connect(db_url)
cur = conn.cursor()

cur.execute("INSERT INTO users (username, password_hash, role) VALUES ('test_trigger_no_email', 'scrypt:test', 'customer') RETURNING id, username, email;")
row = cur.fetchone()
print("Inserted row via raw SQL without email:", row)

cur.execute("DELETE FROM users WHERE id = %s;", (row[0],))
conn.commit()
print("Trigger test completed successfully!")
conn.close()
