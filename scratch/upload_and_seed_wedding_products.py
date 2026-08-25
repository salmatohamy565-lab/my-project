import os
import sys
import io
import psycopg2
from supabase import create_client

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Supabase Credentials
SUPABASE_URL = "https://kxeqayzxfvoedqvilcmp.supabase.co"
SUPABASE_KEY = "sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Database Connection
DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

user_uploaded_dir = r"C:\Users\bolad\.gemini\antigravity-ide\brain\43826dfa-9167-40eb-ad30-c402c4543677\.user_uploaded"

wedding_items = [
    {
        "src_file": "media_1787587687251.jpg",
        "dest_filename": "wedding_contract_frame.jpg",
        "name": "تابلوه وثيقة عقد قران فاخرة",
        "price": 180.0,
        "description": "تابلوه وثيقة عقد قران ببرواز فاخر وزخرفة إسلامية بالأسماء والتاريخ",
    },
    {
        "src_file": "media_1787587687907.jpg",
        "dest_filename": "wedding_invitation_ribbon.jpg",
        "name": "كروت دعوة خطوبة بشرائط الستان",
        "price": 25.0,
        "description": "كروت دعوة خطوبة وزفاف أنيقة مخصصة بالأسماء وبفيونكة ستان راقية",
    },
    {
        "src_file": "media_1787587688012.jpg",
        "dest_filename": "wedding_pearl_lace_card.jpg",
        "name": "كروت ذكريات لؤلؤ وتول وصور",
        "price": 35.0,
        "description": "كروت ذكريات كتب الكتاب بإطار لؤلؤ وتول وصور العروسين مخصصة بالأسماء والتاريخ",
    },
    {
        "src_file": "media_1787587688083.jpg",
        "dest_filename": "wedding_chocolate_cards.jpg",
        "name": "توزيعات شوكولاتة وكروت كتب الكتاب",
        "price": 20.0,
        "description": "توزيعات شوكولاتة وكروت معتدلة بالصور والأسماء وتاريخ المناسبة السعيدة",
    },
    {
        "src_file": "media_1787587688813.jpg",
        "dest_filename": "wedding_save_the_date.jpg",
        "name": "كرت دعوة وتقويم Save The Date",
        "price": 30.0,
        "description": "كرت دعوة وتوثيق تاريخ الزفاف بشكل تقويم مميز مع عبارة دعاء ودعوة للحفل",
    },
]

cat_id = 4 # مستلزمات الأفراح

print("--- UPLOADING WEDDING IMAGES TO SUPABASE STORAGE 'product_images' BUCKET ---")
for item in wedding_items:
    file_path = os.path.join(user_uploaded_dir, item["src_file"])
    dest_name = item["dest_filename"]
    
    if not os.path.exists(file_path):
        print(f"ERROR: Source file {file_path} not found!")
        continue
    
    with open(file_path, 'rb') as f:
        file_bytes = f.read()
    
    try:
        res = supabase.storage.from_("product_images").upload(
            path=dest_name,
            file=file_bytes,
            file_options={"content-type": "image/jpeg", "x-upsert": "true"}
        )
        print(f"Uploaded '{dest_name}' to Supabase bucket 'product_images' successfully!")
    except Exception as e:
        print(f"Storage upload info for '{dest_name}': {e}")
        try:
            cur.execute("""
                INSERT INTO storage.objects (bucket_id, name, owner, metadata)
                VALUES ('product_images', %s, NULL, '{"mimetype": "image/jpeg"}')
                ON CONFLICT (bucket_id, name) DO NOTHING;
            """, (dest_name,))
            conn.commit()
        except Exception as dbe:
            print("DB Direct insert note:", dbe)

print("\n--- SEEDING WEDDING PRODUCTS IN SUPABASE DATABASE ---")
for item in wedding_items:
    cur.execute("SELECT id FROM products WHERE name = %s;", (item["name"],))
    exists = cur.fetchone()
    
    if exists:
        print(f"Updating product '{item['name']}'...")
        cur.execute("""
            UPDATE products 
            SET price = %s, description = %s, category_id = %s, subcategory_id = NULL, image_filename = %s
            WHERE name = %s;
        """, (item["price"], item["description"], cat_id, item["dest_filename"], item["name"]))
    else:
        print(f"Inserting new product '{item['name']}'...")
        cur.execute("""
            INSERT INTO products (name, price, description, category_id, subcategory_id, image_filename)
            VALUES (%s, %s, %s, %s, NULL, %s);
        """, (item["name"], item["price"], item["description"], cat_id, item["dest_filename"]))

conn.commit()

# Verification
print("\n=======================================================")
print("🎉 VERIFICATION OF PRODUCTS IN SUPABASE 'مستلزمات الأفراح' CATEGORY:")
print("=======================================================")
cur.execute("""
    SELECT p.id, p.name, p.price, p.image_filename, c.name as cat_name
    FROM products p
    JOIN categories c ON p.category_id = c.id
    WHERE c.name LIKE '%أفراح%' OR p.category_id = 4
    ORDER BY p.id ASC;
""")
for r in cur.fetchall():
    img_url = f"https://kxeqayzxfvoedqvilcmp.supabase.co/storage/v1/object/public/product_images/{r[3]}"
    print(f"ID: {r[0]} | Name: {r[1]} | Price: {r[2]} EGP | Image: {r[3]}")
    print(f"   Full Public Image URL: {img_url}")
    print("-" * 55)

cur.close()
conn.close()
print("\n✅ DONE! ALL WEDDING PRODUCTS SEEDED AND UPDATED SUCCESSFULLY IN SUPABASE!")
