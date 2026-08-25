import sys
import io
import psycopg2

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

print("Connecting directly to PostgreSQL Database...")
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# 1. Check or create 'الميداليات' category
cur.execute("SELECT id, name FROM categories WHERE name LIKE '%ميدالي%' OR name LIKE '%ميداليات%';")
rows = cur.fetchall()

cat_id = None
if rows:
    cat_id = rows[0][0]
    print(f"Found existing category '{rows[0][1]}' with ID: {cat_id}")
else:
    print("Creating category 'الميداليات'...")
    cur.execute("""
        INSERT INTO categories (name, description)
        VALUES (%s, %s)
        RETURNING id;
    """, ("الميداليات", "قسم الميداليات الأكريليك والخشب المخصصة"))
    cat_id = cur.fetchone()[0]
    conn.commit()

# Keychains products to add
keychains_products = [
    {
        "name": "ميدالية أكريليك 5 سم",
        "price": 75,
        "description": "ميدالية أكريليك مخصصة مقاس 5 سم بحجم مثالي وجودة طباعة عالية",
        "category_id": cat_id,
        "image_filename": "keychain_acrylic_5cm.jpg"
    },
    {
        "name": "ميدالية أكريليك 7 سم",
        "price": 100,
        "description": "ميدالية أكريليك مخصصة مقاس 7 سم بتصميم أنيق وحجم واضح",
        "category_id": cat_id,
        "image_filename": "keychain_acrylic_7cm.jpg"
    },
    {
        "name": "ميدالية خشب 5 سم",
        "price": 50,
        "description": "ميدالية خشبية طبيعية مقاس 5 سم بحفر ليزر مخصص",
        "category_id": cat_id,
        "image_filename": "keychain_wood_5cm.jpg"
    },
    {
        "name": "ميدالية خشب 7 سم",
        "price": 70,
        "description": "ميدالية خشبية فخمة مقاس 7 سم بحفر ليزر عالي الدقة",
        "category_id": cat_id,
        "image_filename": "keychain_wood_7cm.jpg"
    },
    {
        "name": "ميدالية حسب الطلب",
        "price": 0,
        "description": "تصميم ميدالية مخصصة بالكامل حسب طلبك ورغبتك - أرسل لنا التفاصيل والصورة",
        "category_id": cat_id,
        "image_filename": "keychain_custom.jpg"
    }
]

for p in keychains_products:
    cur.execute("SELECT id FROM products WHERE name = %s;", (p["name"],))
    exists = cur.fetchone()
    if exists:
        print(f"Updating product '{p['name']}'...")
        cur.execute("""
            UPDATE products 
            SET price = %s, description = %s, category_id = %s, image_filename = %s
            WHERE name = %s;
        """, (p["price"], p["description"], p["category_id"], p["image_filename"], p["name"]))
    else:
        print(f"Inserting new product '{p['name']}'...")
        cur.execute("""
            INSERT INTO products (name, price, description, category_id, image_filename)
            VALUES (%s, %s, %s, %s, %s);
        """, (p["name"], p["price"], p["description"], p["category_id"], p["image_filename"]))

conn.commit()

# Print inserted products verification
cur.execute("SELECT id, name, price, description FROM products WHERE category_id = %s ORDER BY id ASC;", (cat_id,))
all_items = cur.fetchall()
print("\n--- VERIFICATION: PRODUCTS IN CATEGORY 'الميداليات' IN SUPABASE ---")
for item in all_items:
    print(f"ID: {item[0]} | Name: {item[1]} | Price: {item[2]} EGP | Desc: {item[3]}")

cur.close()
conn.close()
print("\n🎉 SUCCESS! ALL KEYCHAINS PRODUCTS ARE NOW LIVE IN SUPABASE DATABASE.")
