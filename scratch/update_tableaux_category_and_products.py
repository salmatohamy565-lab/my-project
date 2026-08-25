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
src_lights_collage = os.path.join(user_uploaded_dir, "media_1787597257780.jpg")
src_bw_template = os.path.join(user_uploaded_dir, "media_1787597261195.jpg")
src_desk_wall = os.path.join(user_uploaded_dir, "media_1787597266025.jpg")

files_to_copy = [
    (src_lights_collage, os.path.join(assets_dir, "tableaux.jpg"), "tableaux.jpg"),
    (src_lights_collage, os.path.join(assets_dir, "tableau_lights_collage.jpg"), "tableau_lights_collage.jpg"),
    (src_bw_template, os.path.join(assets_dir, "tableau_black_white_template.jpg"), "tableau_black_white_template.jpg"),
    (src_desk_wall, os.path.join(assets_dir, "tableau_desk_wall_collage.jpg"), "tableau_desk_wall_collage.jpg"),
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

# Find Category 'تابلوهات'
cur.execute("SELECT id, name FROM public.categories WHERE name LIKE '%تابلوه%';")
cat_row = cur.fetchone()
if not cat_row:
    print("ERROR: Category 'تابلوهات' not found!")
    sys.exit(1)

cat_id = cat_row[0]
print(f"Category 'تابلوهات' ID = {cat_id}")

# Update Category image_url to 'tableaux.jpg'
cur.execute("UPDATE public.categories SET image_url = 'tableaux.jpg' WHERE id = %s;", (cat_id,))
print("Updated Category image_url to 'tableaux.jpg'")

# Delete old products for tableaux category
cur.execute("DELETE FROM public.products WHERE category_id = %s;", (cat_id,))

products_data = [
    (
        "تابلوه كولاج صور رومانسي مع إضاءة دافئة وتقويم",
        "تابلوه حائطي كبير بطباعة كولاج صور عائلية ورومانسية مع عبارات حب وتقويم مخصص.",
        380.0,
        "tableau_lights_collage.jpg"
    ),
    (
        "تابلوه كولاج صور أسود في أبيض بتصميم القمر",
        "تابلوه خشبي فاخر بتصميم أسود ملكي وكولاج صور متعددة مع عبارات خط عربي مميزة.",
        290.0,
        "tableau_black_white_template.jpg"
    ),
    (
        "تابلوه كولاج صور ومستلزمات ديكور للمكتب والحائط",
        "تابلوه خشبي MDF فاخر طباعة حرارية عالية الجودة بكولاج صور شخصية وتاريخ مناسبة.",
        320.0,
        "tableau_desk_wall_collage.jpg"
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

print("\nSUCCESS: Category cover updated and products added to 'تابلوهات' successfully!")
