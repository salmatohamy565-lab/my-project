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
src_trodat_set = os.path.join(user_uploaded_dir, "media_1787596106549.jpg")
src_shiny_round = os.path.join(user_uploaded_dir, "media_1787596062367.jpg")
src_auto_rect = os.path.join(user_uploaded_dir, "media_1787596068876.jpg")

files_to_copy = [
    (src_trodat_set, os.path.join(assets_dir, "custom_stamp.jpg"), "custom_stamp.jpg"),
    (src_trodat_set, os.path.join(assets_dir, "stamp_trodat_set.jpg"), "stamp_trodat_set.jpg"),
    (src_shiny_round, os.path.join(assets_dir, "stamp_shiny_round.jpg"), "stamp_shiny_round.jpg"),
    (src_auto_rect, os.path.join(assets_dir, "stamp_auto_rectangle.jpg"), "stamp_auto_rectangle.jpg"),
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

# Find Category 'الأختام'
cur.execute("SELECT id, name FROM public.categories WHERE name LIKE '%ختام%' OR name LIKE '%ختم%';")
cat_row = cur.fetchone()
if not cat_row:
    print("ERROR: Category 'الأختام' not found!")
    sys.exit(1)

cat_id = cat_row[0]
print(f"Category 'الأختام' ID = {cat_id}")

# Update Category image_url to 'custom_stamp.jpg'
cur.execute("UPDATE public.categories SET image_url = 'custom_stamp.jpg' WHERE id = %s;", (cat_id,))
print("Updated Category image_url to 'custom_stamp.jpg'")

# Delete old products for stamps category
cur.execute("DELETE FROM public.products WHERE category_id = %s;", (cat_id,))

products_data = [
    (
        "طقم أختام فورية ملونة وتوقيع Trodat",
        "ختم فوري أوتوماتيك بألوان حبر متعددة (أحمر، أزرق، أسود) مخصص لنموذج التوقيع والاعتمادات.",
        350.0,
        "stamp_trodat_set.jpg"
    ),
    (
        "ختم أوتوماتيك دائري Shiny R-542",
        "ختم فوري أوتوماتيك شخصي أو للشركات والمؤسسات قطره 42 مم بآلية ضغط سلسة وغطاء حماية.",
        420.0,
        "stamp_shiny_round.jpg"
    ),
    (
        "ختم أوتوماتيك مستطيل للشركات والأطباء",
        "ختم أوتوماتيك فوري بحجم قياسي مخصص لبيانات الشركات والمحامين والمهندسين والأطباء.",
        280.0,
        "stamp_auto_rectangle.jpg"
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

print("\nSUCCESS: Category cover updated and products added to 'الأختام' successfully!")
