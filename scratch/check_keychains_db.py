import sys
import io
import psycopg2

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

print("--- CATEGORY FOR MEDALS/KEYCHAINS ---")
cur.execute("SELECT id, name FROM categories WHERE name LIKE '%ميدال%' OR id = 5;")
print(cur.fetchall())

print("\n--- SUBCATEGORIES FOR MEDALS/KEYCHAINS ---")
cur.execute("SELECT id, name, category_id FROM subcategories WHERE category_id = 5 OR name LIKE '%ميدال%';")
subcats = cur.fetchall()
print(subcats)

print("\n--- PRODUCTS FOR MEDALS/KEYCHAINS ---")
cur.execute("""
    SELECT p.id, p.name, p.price, p.description, p.image_filename, c.name as cat_name, s.name as subcat_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN subcategories s ON p.subcategory_id = s.id
    WHERE p.category_id = 5 OR c.name LIKE '%ميدال%' OR s.category_id = 5 OR p.name LIKE '%ميدال%'
    ORDER BY p.id ASC;
""")
products = cur.fetchall()
for p in products:
    print(p)

cur.close()
conn.close()
