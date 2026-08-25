import sys
import io
import psycopg2

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

print("--- CATEGORIES ---")
cur.execute("SELECT id, name FROM categories WHERE name LIKE '%شهاد%' OR name LIKE '%شهادات%';")
print(cur.fetchall())

print("\n--- SUBCATEGORIES ---")
cur.execute("SELECT id, name, category_id FROM subcategories WHERE name LIKE '%شهاد%' OR name LIKE '%جلوس%';")
print(cur.fetchall())

print("\n--- PRODUCTS FOR CERTIFICATES ---")
cur.execute("""
    SELECT p.id, p.name, p.price, p.description, p.image_filename, c.name as category_name, s.name as subcategory_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN subcategories s ON p.subcategory_id = s.id
    WHERE c.name LIKE '%شهاد%' OR s.name LIKE '%شهاد%' OR p.name LIKE '%شهاد%' OR p.description LIKE '%شهاد%' OR s.name LIKE '%جلوس%';
""")
for r in cur.fetchall():
    print(r)

cur.close()
conn.close()
