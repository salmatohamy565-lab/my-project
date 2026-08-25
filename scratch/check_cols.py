import sys
import psycopg2

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(pooler_url)
cur = conn.cursor()
cur.execute("SELECT id, name, image_filename FROM public.products ORDER BY id;")
print("All Products with image_filename:")
for r in cur.fetchall():
    print(r)
cur.close()
conn.close()
