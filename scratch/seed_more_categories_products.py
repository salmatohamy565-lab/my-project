import sys
import io
import psycopg2

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

print("Connecting directly to PostgreSQL Database...")
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

def get_or_create_category(cat_name):
    cur.execute("SELECT id, name FROM categories WHERE name LIKE %s;", (f"%{cat_name}%",))
    row = cur.fetchone()
    if row:
        print(f"Found existing category '{row[1]}' with ID: {row[0]}")
        return row[0]
    else:
        print(f"Creating category '{cat_name}'...")
        cur.execute("INSERT INTO categories (name) VALUES (%s) RETURNING id;", (cat_name,))
        new_id = cur.fetchone()[0]
        conn.commit()
        print(f"Created category '{cat_name}' with ID: {new_id}")
        return new_id

# Categories mapping
cat_tshirts_id = get_or_create_category("تيشيرتات")
cat_wallets_id = get_or_create_category("المحافظ")
cat_flags_id = get_or_create_category("الأعلام")
cat_pens_id = get_or_create_category("الأقلام")

# Products list
new_products = [
    # 1. تيشيرتات
    {
        "name": "طباعة التيشيرت الفاتح",
        "price": 50,
        "description": "طباعة حرارية عالية الجودة وثبات ألوان ممتازة على التيشيرتات الفاتحة",
        "category_id": cat_tshirts_id,
        "image_filename": "tshirt_light.jpg"
    },
    {
        "name": "طباعة التيشيرت الغامق",
        "price": 100,
        "description": "طباعة ديجيتال فاخرة وثقيلة للتيشيرتات الغامقة والسوداء مع ثبات ألوان ممتاز",
        "category_id": cat_tshirts_id,
        "image_filename": "tshirt_dark.jpg"
    },
    # 2. المحافظ
    {
        "name": "محفظة حفر وش واحد",
        "price": 160,
        "description": "محفظة جلد طبيعي فاخرة مع حفر ليزر مخصص بالاسم أو الصورة على جهة واحدة",
        "category_id": cat_wallets_id,
        "image_filename": "wallet_single_side.jpg"
    },
    {
        "name": "محفظة حفر وشين",
        "price": 200,
        "description": "محفظة جلد طبيعي فخمة مع حفر ليزر مخصص على الجهتين بأعلى دقة",
        "category_id": cat_wallets_id,
        "image_filename": "wallet_double_side.jpg"
    },
    # 3. الأعلام
    {
        "name": "علم ريشة كبير",
        "price": 700,
        "description": "علم ريشة خارجي (Feather Flag) مقاس كبير مع ستاند وتثبيت ممتاز للشركات والمعارض",
        "category_id": cat_flags_id,
        "image_filename": "flag_feather.jpg"
    },
    {
        "name": "علم مكتب",
        "price": 250,
        "description": "علم مكتب أنيق مع قاعدة وسارية ستانلس فاخرة للمكاتب والشركات",
        "category_id": cat_flags_id,
        "image_filename": "flag_desk.jpg"
    },
    # 4. الأقلام
    {
        "name": "قلم مضيء خط أزرق تاتش",
        "price": 70,
        "description": "قلم فاخر 3 في 1 (قلم جاف أزرق + إضاءة LED مخصصة + رأس تاتش للشاشات الذكية)",
        "category_id": cat_pens_id,
        "image_filename": "pen_light_touch.jpg"
    }
]

for p in new_products:
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
print("\n--- VERIFICATION: NEW PRODUCTS ADDED IN SUPABASE ---")
for cat_name, cid in [("تيشيرتات", cat_tshirts_id), ("المحافظ", cat_wallets_id), ("الأعلام", cat_flags_id), ("الأقلام", cat_pens_id)]:
    cur.execute("SELECT id, name, price, description FROM products WHERE category_id = %s ORDER BY id ASC;", (cid,))
    items = cur.fetchall()
    print(f"\n📁 CATEGORY: {cat_name} (ID: {cid})")
    for item in items:
        print(f"  - ID: {item[0]} | Name: {item[1]} | Price: {item[2]} EGP | Desc: {item[3]}")

cur.close()
conn.close()
print("\n🎉 SUCCESS! ALL T-SHIRTS, WALLETS, FLAGS & PENS PRODUCTS ARE NOW LIVE IN SUPABASE DATABASE.")
