import sys
import io
import psycopg2

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

print("Connecting directly to PostgreSQL Database...")
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# 1. Get or create main category 'شهادات'
cur.execute("SELECT id, name FROM categories WHERE name LIKE '%شهاد%' OR name LIKE '%شهادات%';")
cat_rows = cur.fetchall()

cat_id = None
if cat_rows:
    cat_id = cat_rows[0][0]
    print(f"Found existing main category '{cat_rows[0][1]}' with ID: {cat_id}")
else:
    print("Creating main category 'شهادات'...")
    cur.execute("INSERT INTO categories (name) VALUES (%s) RETURNING id;", ("شهادات",))
    cat_id = cur.fetchone()[0]
    conn.commit()
    print(f"Created main category 'شهادات' with ID: {cat_id}")

# 2. Get or create subcategory 'ورق جلوس' under category 'شهادات'
cur.execute("SELECT id, name FROM subcategories WHERE name LIKE '%جلوس%' OR name LIKE '%ورق جلوس%';")
subcat_rows = cur.fetchall()
subcat_id = None
if subcat_rows:
    subcat_id = subcat_rows[0][0]
    print(f"Found existing subcategory '{subcat_rows[0][1]}' with ID: {subcat_id}")
else:
    print("Creating subcategory 'ورق جلوس'...")
    cur.execute("""
        INSERT INTO subcategories (name, category_id)
        VALUES (%s, %s)
        RETURNING id;
    """, ("ورق جلوس", cat_id))
    subcat_id = cur.fetchone()[0]
    conn.commit()
    print(f"Created subcategory 'ورق جلوس' with ID: {subcat_id}")

# Certificates products list
# Note: DB constraint CHECK requires either category_id IS NOT NULL (and subcategory_id IS NULL)
# OR category_id IS NULL (and subcategory_id IS NOT NULL).
cert_products = [
    {
        "name": "ورق عادى",
        "price": 5,
        "description": "طباعة شهادة تقدير على ورق عادي 80 جرام بجودة ممتازة",
        "category_id": cat_id,
        "subcategory_id": None,
        "image_filename": "certificate_plain.jpg"
    },
    {
        "name": "ورق مقوى",
        "price": 10,
        "description": "طباعة شهادة تقدير على ورق مقوى خامة متينة وألوان زاهية",
        "category_id": cat_id,
        "subcategory_id": None,
        "image_filename": "certificate_cardstock.jpg"
    },
    {
        "name": "ورق جلوس 180 جرام",
        "price": 15,
        "description": "طباعة شهادة فاخرة على ورق جلوس لمعة مقاس 180 جرام",
        "category_id": None,
        "subcategory_id": subcat_id,
        "image_filename": "certificate_glossy_180.jpg"
    },
    {
        "name": "ورق جلوس 200 جرام",
        "price": 20,
        "description": "طباعة شهادة فاخرة على ورق جلوس لميع مقوى 200 جرام",
        "category_id": None,
        "subcategory_id": subcat_id,
        "image_filename": "certificate_glossy_200.jpg"
    },
    {
        "name": "ورق جلوس 260 جرام",
        "price": 25,
        "description": "طباعة شهادة فاخرة على ورق جلوس سميك جداً 260 جرام أعلى جودة",
        "category_id": None,
        "subcategory_id": subcat_id,
        "image_filename": "certificate_glossy_260.jpg"
    },
    {
        "name": "ورق جلوس مضلع",
        "price": 30,
        "description": "طباعة شهادة فخمة على ورق جلوس مضلع بلمسة محفورة رائعة",
        "category_id": None,
        "subcategory_id": subcat_id,
        "image_filename": "certificate_glossy_ribbed.jpg"
    }
]

for p in cert_products:
    cur.execute("SELECT id FROM products WHERE name = %s;", (p["name"],))
    exists = cur.fetchone()
    if exists:
        print(f"Updating product '{p['name']}'...")
        cur.execute("""
            UPDATE products 
            SET price = %s, description = %s, category_id = %s, subcategory_id = %s, image_filename = %s
            WHERE name = %s;
        """, (p["price"], p["description"], p["category_id"], p["subcategory_id"], p["image_filename"], p["name"]))
    else:
        print(f"Inserting new product '{p['name']}'...")
        cur.execute("""
            INSERT INTO products (name, price, description, category_id, subcategory_id, image_filename)
            VALUES (%s, %s, %s, %s, %s, %s);
        """, (p["name"], p["price"], p["description"], p["category_id"], p["subcategory_id"], p["image_filename"]))

conn.commit()

# Print inserted products verification
cur.execute("SELECT id, name, price, category_id, subcategory_id, description FROM products WHERE category_id = %s OR subcategory_id = %s ORDER BY id ASC;", (cat_id, subcat_id))
all_items = cur.fetchall()
print("\n--- VERIFICATION: PRODUCTS IN CATEGORY 'شهادات' & SUBCATEGORY 'ورق جلوس' IN SUPABASE ---")
for item in all_items:
    print(f"ID: {item[0]} | Name: {item[1]} | Price: {item[2]} EGP | CatID: {item[3]} | SubCatID: {item[4]} | Desc: {item[5]}")

cur.close()
conn.close()
print("\n🎉 SUCCESS! ALL CERTIFICATE & GLOSSY PAPER PRODUCTS ARE NOW LIVE IN SUPABASE DATABASE.")
