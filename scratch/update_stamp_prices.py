import sys
import psycopg2

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(pooler_url)
cur = conn.cursor()

print("--- UPDATING STAMP PRICES IN SUPABASE DATABASE ---")

# 1. Update round stamp price to 450.0 EGP
cur.execute("""
    UPDATE public.products
    SET price = 450.0
    WHERE category_id = 15 AND (name LIKE '%دائري%' OR id = 92);
""")
print(f"Updated {cur.rowcount} round stamp product(s) to 450.0 EGP")

# 2. Update rectangular stamp price to 250.0 EGP
cur.execute("""
    UPDATE public.products
    SET price = 250.0
    WHERE category_id = 15 AND (name LIKE '%مستطيل%' OR id = 93);
""")
print(f"Updated {cur.rowcount} rectangular stamp product(s) to 250.0 EGP")

conn.commit()

# Verify updated products
cur.execute("SELECT id, name, price, image_filename FROM public.products WHERE category_id = 15 ORDER BY id;")
print("\nUpdated Products for Category #15 (الأختام):")
for r in cur.fetchall():
    print(r)

cur.close()
conn.close()

print("\nSUCCESS: Stamp prices updated successfully!")
