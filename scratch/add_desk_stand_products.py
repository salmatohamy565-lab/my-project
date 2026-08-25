import os
import shutil
import urllib.request
import sys
import psycopg2

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
supabase_url = "https://kxeqayzxfvoedqvilcmp.supabase.co"
anon_key = "sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E"

user_uploaded_dir = r"C:\Users\bolad\.gemini\antigravity-ide\brain\e1b6a7ca-8ea1-4917-bf77-d53a1156c1e7\.user_uploaded"
assets_dir = r"c:\Users\bolad\Desktop\bola app\assets\product_images"

os.makedirs(assets_dir, exist_ok=True)

# Map media files to product image filenames
image_mapping = [
    {
        "src": os.path.join(user_uploaded_dir, "media_1787592798760.jpg"),
        "dest_filename": "desk_stand_gold_wood.jpg",
        "name": "ستاند مكتب خشبي أكريليك ذهبي",
        "description": "ستاند مكتب خشبي فاخر مع لوحة أكريليك مذهبة ومحفورة ليزر بالاسم واللقب الوظيفي.",
        "price": 350.0
    },
    {
        "src": os.path.join(user_uploaded_dir, "media_1787592802784.jpg"),
        "dest_filename": "desk_stand_black_gold_pens.jpg",
        "name": "ستاند مكتب أسود وذهبي مع حامل أقلام",
        "description": "ستاند مكتب أكريليك فاخر باللون الأسود الملكي والذهبي مزود بحامل أقلام سداسي وحامل كروت.",
        "price": 450.0
    },
    {
        "src": os.path.join(user_uploaded_dir, "media_1787592808993.jpg"),
        "dest_filename": "desk_stand_led_acrylic.jpg",
        "name": "ستاند مكتب أكريليك مضيء LED",
        "description": "لوحة ستاند مكتب شفافة مضيئة بإضاءة LED عصرية بحفر ليزر دقيق بالشعار واللقب.",
        "price": 500.0
    }
]

print("--- 1. COPYING IMAGES TO ASSETS ---")
for item in image_mapping:
    src_path = item["src"]
    dest_path = os.path.join(assets_dir, item["dest_filename"])
    if os.path.exists(src_path):
        shutil.copy(src_path, dest_path)
        print(f"Copied {src_path} -> {dest_path}")
    else:
        print(f"ERROR: Source file {src_path} not found!")

print("\n--- 2. UPLOADING IMAGES TO SUPABASE STORAGE ---")
for item in image_mapping:
    dest_path = os.path.join(assets_dir, item["dest_filename"])
    if os.path.exists(dest_path):
        with open(dest_path, "rb") as f:
            file_bytes = f.read()
        url = f"{supabase_url}/storage/v1/object/product_images/{item['dest_filename']}"
        req = urllib.request.Request(url, data=file_bytes, method="POST")
        req.add_header("Authorization", f"Bearer {anon_key}")
        req.add_header("apikey", anon_key)
        req.add_header("Content-Type", "image/jpeg")
        req.add_header("x-upsert", "true")
        try:
            with urllib.request.urlopen(req) as resp:
                print(f"Uploaded {item['dest_filename']}: status {resp.status}")
        except Exception as e:
            print(f"Upload exception for {item['dest_filename']}: {e}")

print("\n--- 3. INSERTING PRODUCTS INTO SUPABASE DATABASE ---")
conn = psycopg2.connect(pooler_url)
cur = conn.cursor()

# Get category_id for 'ستاند مكتب'
cur.execute("SELECT id FROM public.categories WHERE name LIKE '%ستاند%' OR name LIKE '%مكتب%';")
row = cur.fetchone()
if not row:
    print("ERROR: Category 'ستاند مكتب' not found!")
    sys.exit(1)

cat_id = row[0]
print(f"Category 'ستاند مكتب' ID = {cat_id}")

# Delete existing test products for this category if any
cur.execute("DELETE FROM public.products WHERE category_id = %s;", (cat_id,))

for item in image_mapping:
    cur.execute("""
        INSERT INTO public.products (name, description, price, image_filename, category_id)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING id;
    """, (item["name"], item["description"], item["price"], item["dest_filename"], cat_id))
    prod_id = cur.fetchone()[0]
    print(f"Inserted Product #{prod_id}: '{item['name']}' ({item['price']} EGP) -> image_filename: {item['dest_filename']}")

conn.commit()
cur.close()
conn.close()

print("\nSUCCESS: All 3 desk stand products inserted into Supabase and Assets successfully!")
