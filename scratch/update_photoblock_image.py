import sys
import psycopg2

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(pooler_url)
cur = conn.cursor()

# Update image_filename to 'frames.jpg' for photoblock products
cur.execute("""
    UPDATE public.products
    SET image_filename = 'frames.jpg'
    WHERE name LIKE '%فوتوبلوك%' OR subcategory_id = 3;
""")

print(f"Updated {cur.rowcount} photoblock products to image_filename = 'frames.jpg'")

conn.commit()

cur.execute("SELECT id, name, image_filename FROM public.products WHERE name LIKE '%فوتوبلوك%' OR subcategory_id = 3;")
for r in cur.fetchall():
    print(r)

cur.close()
conn.close()
