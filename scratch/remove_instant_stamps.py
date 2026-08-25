import sys
import psycopg2

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(pooler_url)
cur = conn.cursor()

print("--- REMOVING INSTANT STAMPS FROM CATEGORY #15 (الأختام) ---")

# Delete product #91 / 'طقم أختام فورية ملونة وتوقيع Trodat'
cur.execute("""
    DELETE FROM public.products
    WHERE category_id = 15 AND (id = 91 OR name LIKE '%فورية%');
""")

print(f"Deleted {cur.rowcount} product(s) from Category #15")

conn.commit()

# Verify remaining products in Category #15
cur.execute("SELECT id, name, price, image_filename FROM public.products WHERE category_id = 15 ORDER BY id;")
print("\nRemaining Products in Category #15 (الأختام):")
for r in cur.fetchall():
    print(r)

cur.close()
conn.close()

print("\nSUCCESS: Product removed successfully and remaining stamps left unchanged!")
