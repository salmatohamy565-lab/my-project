import psycopg2

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
conn = psycopg2.connect(db_url)
cur = conn.cursor()

tables_cols = [
    ('tasks', 'assigned_to'),
    ('attendance', 'user_id'),
    ('orders', 'user_id'),
    ('notifications', 'user_id')
]

for tbl, col in tables_cols:
    cur.execute(f"""
        SELECT constraint_name 
        FROM information_schema.key_column_usage 
        WHERE table_name = '{tbl}' AND column_name = '{col}';
    """)
    rows = cur.fetchall()
    for (cname,) in rows:
        print(f"Dropping constraint {cname} on {tbl}({col})...")
        cur.execute(f'ALTER TABLE {tbl} DROP CONSTRAINT IF EXISTS "{cname}";')
    print(f"Adding CASCADE constraint on {tbl}({col})...")
    cur.execute(f'ALTER TABLE {tbl} ADD CONSTRAINT fk_{tbl}_{col}_users FOREIGN KEY ({col}) REFERENCES users(id) ON DELETE CASCADE;')

conn.commit()
print("ALL FOREIGN KEYS CASCADE MIGRATION COMPLETED SUCCESSFULLY!")
conn.close()
