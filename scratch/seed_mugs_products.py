import sys
import io
import psycopg2

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

print("Connecting directly to PostgreSQL Database...")
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# Get column names of products table
cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'products';")
cols = [r[0] for r in cur.fetchall()]
print(f"Products table columns: {cols}")

# 1. Get or create category 'المجات'
cur.execute("SELECT id, name FROM categories WHERE name LIKE '%مج%' OR name LIKE '%مجات%';")
rows = cur.fetchall()

cat_id = None
if rows:
    cat_id = rows[0][0]
    print(f"Found existing category ID: {cat_id}")
else:
    print("Creating category 'المجات'...")
    cur.execute("""
        INSERT INTO categories (name, description)
        VALUES (%s, %s)
        RETURNING id;
    """, ("المجات", "قسم المجات والتصاميم الحرارية المخصصة"))
    cat_id = cur.fetchone()[0]
    conn.commit()

# Products list
mugs_products = [
    {
        "name": "مج سحري",
        "price": 150,
        "description": "اول م تحط مشروبك صورتك او اسمك يظهروا",
        "category_id": cat_id,
        "image_filename": "mug_magic.jpg"
    },
    {
        "name": "مج أبيض",
        "price": 120,
        "description": "مج بصورتك",
        "category_id": cat_id,
        "image_filename": "mug_white.jpg"
    },
    {
        "name": "مج ديجيتال",
        "price": 150,
        "description": "اختار الوان مجك",
        "category_id": cat_id,
        "image_filename": "mug_digital.jpg"
    },
    {
        "name": "مج عدسة",
        "price": 150,
        "description": "مج حراري عدسة",
        "category_id": cat_id,
        "image_filename": "mug_lens.jpg"
    },
    {
        "name": "مج عدسة كبير",
        "price": 170,
        "description": "مج حراري عدسة كبير",
        "category_id": cat_id,
        "image_filename": "mug_lens_large.jpg"
    },
    {
        "name": "مج أزاز باسم",
        "price": 150,
        "description": "مج إزاز باسمك",
        "category_id": cat_id,
        "image_filename": "mug_glass.jpg"
    }
]

for p in mugs_products:
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
all_mugs = cur.fetchall()
print("\n--- VERIFICATION: PRODUCTS IN CATEGORY 'المجات' IN SUPABASE ---")
for mug in all_mugs:
    print(f"ID: {mug[0]} | Name: {mug[1]} | Price: {mug[2]} EGP | Desc: {mug[3]}")

cur.close()
conn.close()
print("\n🎉 SUCCESS! ALL MUG PRODUCTS ARE NOW LIVE IN SUPABASE DATABASE.")
