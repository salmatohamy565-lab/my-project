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

# File mappings
cat_cover_src = os.path.join(user_uploaded_dir, "media_1787594409450.jpg")

p1_src = os.path.join(user_uploaded_dir, "media_1787594409450.jpg")
p2_src = os.path.join(user_uploaded_dir, "media_1787594306875.jpg")
p3_src = os.path.join(user_uploaded_dir, "media_1787594309565.jpg")
p4_src = os.path.join(user_uploaded_dir, "media_1787594366500.jpg")

files_to_copy = [
    (cat_cover_src, os.path.join(assets_dir, "pens.jpg"), "pens.jpg"),
    (p1_src, os.path.join(assets_dir, "pen_gold_luxury_box.jpg"), "pen_gold_luxury_box.jpg"),
    (p2_src, os.path.join(assets_dir, "pen_touch_laser_engraved.jpg"), "pen_touch_laser_engraved.jpg"),
    (p3_src, os.path.join(assets_dir, "pen_corporate_set.jpg"), "pen_corporate_set.jpg"),
    (p4_src, os.path.join(assets_dir, "pen_classic_silver_clip.jpg"), "pen_classic_silver_clip.jpg"),
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

# Find Category 'الأقلام'
cur.execute("SELECT id, name FROM public.categories WHERE name LIKE '%قلام%';")
cat_row = cur.fetchone()
if not cat_row:
    print("ERROR: Category 'الأقلام' not found!")
    sys.exit(1)

cat_id = cat_row[0]
print(f"Category 'الأقلام' ID = {cat_id}")

# Update Category image_url to 'pens.jpg'
cur.execute("UPDATE public.categories SET image_url = 'pens.jpg' WHERE id = %s;", (cat_id,))
print("Updated Category image_url to 'pens.jpg'")

# Delete old products for pens category
cur.execute("DELETE FROM public.products WHERE category_id = %s;", (cat_id,))

products_data = [
    (
        "قلم فاخر مطعم بالذهبي مع علبة هدايا",
        "طقم قلم معدني فاخر بتطعيمات مذهبة وحفر ليزر مخصص للأسماء والعبارات مع علبة هدايا فاخرة.",
        150.0,
        "pen_gold_luxury_box.jpg"
    ),
    (
        "قلم تاتش سكرين معدني بحفر ليزر",
        "قلم تاتش سكرين 2 في 1 معدني أسود فاخر بحفر ليزر فضي دقيق للأسماء والشركات.",
        85.0,
        "pen_touch_laser_engraved.jpg"
    ),
    (
        "أطقم أقلام دعايا واجتماعات محفورة",
        "أقلام مكتبية وتنفيذية مخصصة للشركات والفعاليات بحفر الشعار والأسماء.",
        65.0,
        "pen_corporate_set.jpg"
    ),
    (
        "قلم معدني كلاسيك بمشبك فضي محفور",
        "قلم معدني أسود أنيق بمشبك فضي كلاسيكي وحفر ليزر دقيق بالاسم واللقب.",
        110.0,
        "pen_classic_silver_clip.jpg"
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

print("\nSUCCESS: Category cover updated and products added to 'الأقلام' successfully!")
