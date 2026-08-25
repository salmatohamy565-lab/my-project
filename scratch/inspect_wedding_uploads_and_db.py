import os
import sys
import io
import psycopg2

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

brain_dir = r"C:\Users\bolad\.gemini\antigravity-ide\brain"
conv_id = "43826dfa-9167-40eb-ad30-c402c4543677"
user_dir = os.path.join(brain_dir, conv_id, ".user_uploaded")

print("--- LATEST UPLOADED FILES ---")
if os.path.exists(user_dir):
    files = sorted(os.listdir(user_dir), key=lambda x: os.path.getmtime(os.path.join(user_dir, x)))
    for f in files[-7:]:
        full_p = os.path.join(user_dir, f)
        print(f"  {f} - {os.path.getsize(full_p)} bytes - modified {os.path.getmtime(full_p)}")

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

print("\n--- CATEGORY FOR WEDDING SUPPLIES ---")
cur.execute("SELECT id, name FROM categories WHERE name LIKE '%أفراح%' OR name LIKE '%فرح%' OR id = 4;")
print(cur.fetchall())

print("\n--- SUBCATEGORIES FOR WEDDING SUPPLIES ---")
cur.execute("SELECT id, name, category_id FROM subcategories WHERE category_id = 4 OR name LIKE '%فرح%' OR name LIKE '%أفراح%';")
subcats = cur.fetchall()
print(subcats)

print("\n--- PRODUCTS IN WEDDING SUPPLIES CATEGORY ---")
cur.execute("""
    SELECT p.id, p.name, p.price, p.description, p.image_filename, c.name as cat_name, s.name as subcat_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN subcategories s ON p.subcategory_id = s.id
    WHERE p.category_id = 4 OR c.name LIKE '%أفراح%' OR s.category_id = 4
    ORDER BY p.id ASC;
""")
products = cur.fetchall()
for p in products:
    print(p)

cur.close()
conn.close()
