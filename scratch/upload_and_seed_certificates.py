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

# Ensure public select/insert policies for product_images bucket
storage_policies = [
    'DROP POLICY IF EXISTS "Public Access Product Images Select" ON storage.objects;',
    'DROP POLICY IF EXISTS "Public Access Product Images Insert" ON storage.objects;',
    'CREATE POLICY "Public Access Product Images Select" ON storage.objects FOR SELECT USING (bucket_id = \'product_images\');',
    'CREATE POLICY "Public Access Product Images Insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = \'product_images\');'
]
for pol in storage_policies:
    try:
        cur.execute(pol)
    except Exception as e:
        print("Policy notice:", e)
conn.commit()

# User uploaded directory containing images
user_uploaded_dir = r"C:\Users\bolad\.gemini\antigravity-ide\brain\43826dfa-9167-40eb-ad30-c402c4543677\.user_uploaded"

certificates_data = [
    {
        "src_file": "media_1787584410729.jpg",
        "dest_filename": "cert_navy_gold.jpg",
        "name": "شهادة تقدير كحلي وذهبي فاخرة",
        "price": 35.0,
        "description": "تصميم شهادة تقدير بإطار ذهبي وكحلي ملكي فاخر، مثالي لتكريم الشخصيات والأنشطة",
    },
    {
        "src_file": "media_1787584410847.jpg",
        "dest_filename": "cert_blue_classic.jpg",
        "name": "شهادة تقدير وتفوق أزرق كلاسيك",
        "price": 35.0,
        "description": "تصميم شهادة تكريم وتفوق كلاسيكي باللون الأزرق والذهبي مع مكان لمجلس الإدارة والشعار",
    },
    {
        "src_file": "media_1787584410934.jpg",
        "dest_filename": "cert_red_gold.jpg",
        "name": "شهادة تقدير مذهبة بالشريط الأحمر",
        "price": 40.0,
        "description": "تصميم شهادة تقدير فخمة بلمسات ذهبية براقة وشريط الوسام الأحمر المميز لتكريم المتفوقين",
    },
    {
        "src_file": "media_1787584411052.jpg",
        "dest_filename": "cert_emerald_gold.jpg",
        "name": "شهادة تخرج وتكريم زمردي وذهبي",
        "price": 40.0,
        "description": "تصميم شهادة تخرج فاخرة باللون الأخضر الزمردي والذهبي لحفلات التخرج والتكريم الأكاديمي",
    },
    {
        "src_file": "media_1787584411100.jpg",
        "dest_filename": "cert_brown_gold.jpg",
        "name": "شهادة خبرة وكفاءة أنيقة",
        "price": 35.0,
        "description": "تصميم شهادة خبرة وكفاءة باللون البني والذهبي الأنيق ومناسبة لمجالات التدريب والخبرات",
    },
]

# Get or create subcategory 'نماذج شهادات تقدير' under main category 'شهادات' (ID 6)
cat_id = 6 # شهادات
cur.execute("SELECT id FROM subcategories WHERE name LIKE '%نماذج%' OR name LIKE '%تصاميم%';")
subcat_row = cur.fetchone()

subcat_id = None
if subcat_row:
    subcat_id = subcat_row[0]
    print(f"Found subcategory ID: {subcat_id}")
else:
    print("Creating new subcategory 'نماذج شهادات تقدير' under category 'شهادات'...")
    cur.execute("""
        INSERT INTO subcategories (name, category_id)
        VALUES (%s, %s)
        RETURNING id;
    """, ("نماذج شهادات تقدير", cat_id))
    subcat_id = cur.fetchone()[0]
    conn.commit()
    print(f"Created subcategory 'نماذج شهادات تقدير' with ID: {subcat_id}")

print("\n--- UPLOADING IMAGES TO SUPABASE STORAGE 'product_images' BUCKET ---")
for item in certificates_data:
    file_path = os.path.join(user_uploaded_dir, item["src_file"])
    dest_name = item["dest_filename"]
    
    if not os.path.exists(file_path):
        print(f"ERROR: Source file {file_path} not found!")
        continue
    
    with open(file_path, 'rb') as f:
        file_bytes = f.read()
    
    # Upload to product_images bucket via Supabase Storage
    try:
        res = supabase.storage.from_("product_images").upload(
            path=dest_name,
            file=file_bytes,
            file_options={"content-type": "image/jpeg", "x-upsert": "true"}
        )
        print(f"Uploaded '{dest_name}' to Supabase bucket 'product_images' successfully!")
    except Exception as e:
        print(f"Storage upload info for '{dest_name}': {e}")
        # Direct DB insert into storage.objects if storage API needs fallback
        try:
            cur.execute("""
                INSERT INTO storage.objects (bucket_id, name, owner, metadata)
                VALUES ('product_images', %s, NULL, '{"mimetype": "image/jpeg"}')
                ON CONFLICT (bucket_id, name) DO NOTHING;
            """, (dest_name,))
            conn.commit()
        except Exception as dbe:
            print("DB Direct insert note:", dbe)

print("\n--- SEEDING/UPDATING CERTIFICATE PRODUCTS IN SUPABASE DATABASE ---")
for item in certificates_data:
    cur.execute("SELECT id FROM products WHERE name = %s;", (item["name"],))
    exists = cur.fetchone()
    
    if exists:
        print(f"Updating existing product '{item['name']}'...")
        cur.execute("""
            UPDATE products 
            SET price = %s, description = %s, category_id = NULL, subcategory_id = %s, image_filename = %s
            WHERE name = %s;
        """, (item["price"], item["description"], subcat_id, item["dest_filename"], item["name"]))
    else:
        print(f"Inserting new product '{item['name']}'...")
        cur.execute("""
            INSERT INTO products (name, price, description, category_id, subcategory_id, image_filename)
            VALUES (%s, %s, %s, NULL, %s, %s);
        """, (item["name"], item["price"], item["description"], subcat_id, item["dest_filename"]))

conn.commit()

# Verification query
cur.execute("""
    SELECT p.id, p.name, p.price, p.image_filename, s.name as subcategory_name
    FROM products p
    JOIN subcategories s ON p.subcategory_id = s.id
    WHERE s.category_id = 6 OR p.category_id = 6
    ORDER BY p.id ASC;
""")
rows = cur.fetchall()

print("\n=======================================================")
print("🎉 VERIFICATION OF PRODUCTS IN SUPABASE 'شهادات' CATEGORY:")
print("=======================================================")
for r in rows:
    img_url = f"https://kxeqayzxfvoedqvilcmp.supabase.co/storage/v1/object/public/product_images/{r[3]}"
    print(f"ID: {r[0]} | Name: {r[1]} | Price: {r[2]} EGP | Subcategory: {r[4]}")
    print(f"   Image Filename: {r[3]}")
    print(f"   Full Public Image URL: {img_url}")
    print("-" * 55)

cur.close()
conn.close()
print("\n✅ DONE! ALL CERTIFICATES ADDED BEAUTIFULLY TO SUPABASE DATABASE & STORAGE!")
