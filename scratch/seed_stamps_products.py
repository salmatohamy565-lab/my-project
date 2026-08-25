import sys
import io
import psycopg2

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

print("Connecting directly to PostgreSQL Database...")
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# 1. Check or create 'الأختام' category
cur.execute("SELECT id, name FROM categories WHERE name LIKE '%ختم%' OR name LIKE '%أختام%' OR name LIKE '%الأختام%';")
rows = cur.fetchall()

cat_id = None
if rows:
    cat_id = rows[0][0]
    print(f"Found existing category '{rows[0][1]}' with ID: {cat_id}")
else:
    print("Creating category 'الأختام'...")
    cur.execute("""
        INSERT INTO categories (name)
        VALUES (%s)
        RETURNING id;
    """, ("الأختام",))
    cat_id = cur.fetchone()[0]
    conn.commit()
    print(f"Created category 'الأختام' with ID: {cat_id}")

# Stamps products to add
stamps_products = [
    {
        "name": "ختم مستطيل 2.2 × 5.8 سم",
        "price": 250,
        "description": "ختم أوتوماتيك مستطيل مقاس 2.2 × 5.8 سم عالي الدقة للشركات والمكاتب والأفراد",
        "category_id": cat_id,
        "image_filename": "stamp_rectangle.jpg"
    },
    {
        "name": "ختم دائري 4 سم",
        "price": 450,
        "description": "ختم أوتوماتيك دائري مقاس 4 سم بصمة واضحة ومقاومة للتأكل",
        "category_id": cat_id,
        "image_filename": "stamp_round_4cm.jpg"
    },
    {
        "name": "ختم دائري 4.5 سم",
        "price": 550,
        "description": "ختم أوتوماتيك دائري مقاس 4.5 سم تصميم فخم ومساحة طباعة واسعة",
        "category_id": cat_id,
        "image_filename": "stamp_round_4.5cm.jpg"
    }
]

for p in stamps_products:
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
print("\n--- VERIFICATION: PRODUCTS IN CATEGORY 'الأختام' IN SUPABASE ---")
for item in all_items:
    print(f"ID: {item[0]} | Name: {item[1]} | Price: {item[2]} EGP | Desc: {item[3]}")

cur.close()
conn.close()
print("\n🎉 SUCCESS! ALL STAMPS PRODUCTS ARE NOW LIVE IN SUPABASE DATABASE.")
