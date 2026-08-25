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
src_grad_cap = os.path.join(user_uploaded_dir, "media_1787595167797.jpg")
src_wood_photo = os.path.join(user_uploaded_dir, "media_1787595107939.jpg")
src_quran_cert = os.path.join(user_uploaded_dir, "media_1787595137249.jpg")
src_little_grad = os.path.join(user_uploaded_dir, "media_1787595141893.jpg")

files_to_copy = [
    (src_grad_cap, os.path.join(assets_dir, "trophies.jpg"), "trophies.jpg"),
    (src_grad_cap, os.path.join(assets_dir, "trophy_grad_cap_luxury.jpg"), "trophy_grad_cap_luxury.jpg"),
    (src_wood_photo, os.path.join(assets_dir, "trophy_wood_grad_photo.jpg"), "trophy_wood_grad_photo.jpg"),
    (src_quran_cert, os.path.join(assets_dir, "trophy_acrylic_quran_certificate.jpg"), "trophy_acrylic_quran_certificate.jpg"),
    (src_little_grad, os.path.join(assets_dir, "trophy_acrylic_little_graduate.jpg"), "trophy_acrylic_little_graduate.jpg"),
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

# Find Category 'دروع'
cur.execute("SELECT id, name FROM public.categories WHERE name LIKE '%دروع%' OR name LIKE '%درع%';")
cat_row = cur.fetchone()
if not cat_row:
    print("ERROR: Category 'دروع' not found!")
    sys.exit(1)

cat_id = cat_row[0]
print(f"Category 'دروع' ID = {cat_id}")

# Update Category image_url to 'trophies.jpg'
cur.execute("UPDATE public.categories SET image_url = 'trophies.jpg' WHERE id = %s;", (cat_id,))
print("Updated Category image_url to 'trophies.jpg'")

# Delete old products for trophies category
cur.execute("DELETE FROM public.products WHERE category_id = %s;", (cat_id,))

products_data = [
    (
        "درع التخرج الأسود والمذهب 2025 بقبعة التخرج",
        "درع أكريليك أسود مذهب فاخر بتصميم قبعة التخرج وعبارات التهنئة الخاصة للمتفوقين.",
        450.0,
        "trophy_grad_cap_luxury.jpg"
    ),
    (
        "درع تخرج خشبي مع إطار صورة إهداء",
        "درع تكريم خشبي فاخر بتصميم دائري لصورة الطالب وعبارات التهنئة مع قاعدة أكريليك مذهبة.",
        380.0,
        "trophy_wood_grad_photo.jpg"
    ),
    (
        "درع أكريليك شفاف شهادة حفظ القرآن والإتقان",
        "درع أكريليك شفاف فاخر بحواف مذهبة وقاعدة خشبية محفورة لآيات القرآن وشهادات التكريم.",
        420.0,
        "trophy_acrylic_quran_certificate.jpg"
    ),
    (
        "درع مجسم خريجنا الصغير للأطفال والطلاب",
        "درع أكريليك مجسم بتصميم الخريج الصغير وشهادة تقدير للأطفال وطلاب الروضة والابتدائي.",
        320.0,
        "trophy_acrylic_little_graduate.jpg"
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

print("\nSUCCESS: Category cover updated and products added to 'دروع' successfully!")
