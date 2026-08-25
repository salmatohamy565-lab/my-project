import sys
import psycopg2

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(pooler_url)
cur = conn.cursor()

print("--- UPDATING FLAG PRICES IN SUPABASE DATABASE ---")

# 1. Update desk flag price to 250.0 EGP
cur.execute("""
    UPDATE public.products
    SET price = 250.0
    WHERE category_id = 18 AND (name LIKE '%مكتب%' OR id = 81);
""")
print(f"Updated {cur.rowcount} desk flag product(s) to 250.0 EGP")

# 2. Update feather flag price to 700.0 EGP
cur.execute("""
    UPDATE public.products
    SET price = 700.0
    WHERE category_id = 18 AND (name LIKE '%ريشة%' OR id = 82);
""")
print(f"Updated {cur.rowcount} feather flag product(s) to 700.0 EGP")

conn.commit()

# Verify updated products
cur.execute("SELECT id, name, price, image_filename FROM public.products WHERE category_id = 18 ORDER BY id;")
print("\nUpdated Products for Category #18 (الأعلام):")
for r in cur.fetchall():
    print(r)

cur.close()
conn.close()

print("\nSUCCESS: Flag prices updated successfully!")
