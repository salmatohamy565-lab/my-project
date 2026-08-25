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

# Sources
src_black_gold = os.path.join(user_uploaded_dir, "media_1787596611306.jpg")
src_white_uniform = os.path.join(user_uploaded_dir, "media_1787596664387.jpg")

files_to_copy = [
    (src_black_gold, os.path.join(assets_dir, "tshirts.jpg"), "tshirts.jpg"),
    (src_black_gold, os.path.join(assets_dir, "tshirt_black_gold_arabic.jpg"), "tshirt_black_gold_arabic.jpg"),
    (src_white_uniform, os.path.join(assets_dir, "tshirt_white_uniform_cap.jpg"), "tshirt_white_uniform_cap.jpg"),
]

print("--- 1. COPYING IMAGES TO ASSETS ---")
for src, dest, filename in files_to_copy:
    if os.path.exists(src):
        shutil.copy(src, dest)
        print(f"Copied {filename} to {dest}")
    else:
        print(f"ERROR: Source {src} not found!")

print("\n--- 2. UPLOADING IMAGES TO SUPABASE STORAGE ---")
for src, dest, filename in files_to_copy:
    if os.path.exists(dest):
        with open(dest, "rb") as f:
            file_bytes = f.read()
        url = f"{supabase_url}/storage/v1/object/product_images/{filename}"
        req = urllib.request.Request(url, data=file_bytes, method="POST")
        req.add_header("Authorization", f"Bearer {anon_key}")
        req.add_header("apikey", anon_key)
        req.add_header("Content-Type", "image/jpeg")
        req.add_header("x-upsert", "true")
        try:
            with urllib.request.urlopen(req) as resp:
                print(f"Uploaded {filename}: status {resp.status}")
        except Exception as e:
            print(f"Upload exception for {filename}: {e}")

print("\n--- 3. UPDATING CATEGORY AND PRODUCTS IN SUPABASE DATABASE ---")
conn = psycopg2.connect(pooler_url)
cur = conn.cursor()

# Find Category 'تيشيرتات' / 'تيشرتات'
cur.execute("SELECT id, name FROM public.categories WHERE name LIKE '%تيشرت%' OR name LIKE '%تيشيرت%';")
cat_row = cur.fetchone()
if not cat_row:
    print("ERROR: Category 'تيشيرتات' not found!")
    sys.exit(1)

cat_id = cat_row[0]
print(f"Category 'تيشيرتات' ID = {cat_id}")

# Update Category image_url to 'tshirts.jpg'
cur.execute("UPDATE public.categories SET image_url = 'tshirts.jpg' WHERE id = %s;", (cat_id,))
print("Updated Category image_url to 'tshirts.jpg'")

# Delete old products for tshirts category
cur.execute("DELETE FROM public.products WHERE category_id = %s;", (cat_id,))

products_data = [
    (
        "طباعة تيشيرت أسود قطن بالذهبي والخط العربي",
        "تيشيرت أسود قطن 100% فاخر مطبوع باللون الذهبي البارز للتصاميم والأسماء بالخط العربي.",
        220.0,
        "tshirt_black_gold_arabic.jpg"
    ),
    (
        "طقم تيشيرت ودريس كود شركات مع كاب مطبوع",
        "طقم تيشيرت أبيض قطني مخصص ليونيفرم الشركات والمؤسسات طباعة وش وضهر مع كاب مطبوع باللوجو.",
        280.0,
        "tshirt_white_uniform_cap.jpg"
    )
]

for name, desc, price, img_file in products_data:
    cur.execute("""
        INSERT INTO public.products (name, description, price, image_filename, category_id)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING id;
    """, (name, desc, price, img_file, cat_id))
    p_id = cur.fetchone()[0]
    print(f"Inserted Product #{p_id}: '{name}' ({price} EGP) -> {img_file}")

conn.commit()
cur.close()
conn.close()

print("\nSUCCESS: Category cover updated and products added to 'تيشيرتات' successfully!")
