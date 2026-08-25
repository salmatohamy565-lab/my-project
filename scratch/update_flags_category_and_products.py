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

# 1. Category Cover Image (Image with 3 flags)
cat_cover_src = os.path.join(user_uploaded_dir, "media_1787593366294.jpg")
cat_cover_dest = os.path.join(assets_dir, "flags.jpg")

# 2. Product 1 Image (Desk flag on meeting table)
prod1_src = os.path.join(user_uploaded_dir, "media_1787593332756.jpg")
prod1_dest = os.path.join(assets_dir, "flag_desk_luxury.jpg")

# 3. Product 2 Image (Blue feather flags mockup)
prod2_src = os.path.join(user_uploaded_dir, "media_1787593337166.jpg")
prod2_dest = os.path.join(assets_dir, "flag_feather_blue.jpg")

files_to_copy = [
    (cat_cover_src, cat_cover_dest, "flags.jpg"),
    (prod1_src, prod1_dest, "flag_desk_luxury.jpg"),
    (prod2_src, prod2_dest, "flag_feather_blue.jpg"),
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

print("\n--- 3. UPDATING CATEGORY AND PRODUCTS IN SUPABASE ---")
conn = psycopg2.connect(pooler_url)
cur = conn.cursor()

# Find Category 'الأعلام'
cur.execute("SELECT id, name FROM public.categories WHERE name LIKE '%اعلام%' OR name LIKE '%علام%';")
cat_row = cur.fetchone()
if not cat_row:
    print("ERROR: Category 'الأعلام' not found!")
    sys.exit(1)

cat_id = cat_row[0]
print(f"Category 'الأعلام' ID = {cat_id}")

# Update Category image_url to 'flags.jpg'
cur.execute("UPDATE public.categories SET image_url = 'flags.jpg' WHERE id = %s;", (cat_id,))
print("Updated Category image_url to 'flags.jpg'")

# Delete old products for flags category
cur.execute("DELETE FROM public.products WHERE category_id = %s;", (cat_id,))

# Insert Product 1: Desk Flag
cur.execute("""
    INSERT INTO public.products (name, description, price, image_filename, category_id)
    VALUES (%s, %s, %s, %s, %s)
    RETURNING id;
""", (
    "علم مكتب معدني فاخر باللوجو",
    "علم مكتب ستانلس ستيل فاخر مقاس مخصص مطبوع باللوجو الخاص بالشركات والمؤسسات.",
    250.0,
    "flag_desk_luxury.jpg",
    cat_id
))
p1_id = cur.fetchone()[0]
print(f"Inserted Product #{p1_id}: 'علم مكتب معدني فاخر باللوجو' (250 EGP)")

# Insert Product 2: Feather Flag
cur.execute("""
    INSERT INTO public.products (name, description, price, image_filename, category_id)
    VALUES (%s, %s, %s, %s, %s)
    RETURNING id;
""", (
    "علم ريشة وطاولة خارجية للشركات",
    "أعلام ريشة قماشية عالية الجودة مقاومة للعوامل الجوية والرياح مع قاعدة تثبيت معدنية.",
    700.0,
    "flag_feather_blue.jpg",
    cat_id
))
p2_id = cur.fetchone()[0]
print(f"Inserted Product #{p2_id}: 'علم ريشة وطاولة خارجية للشركات' (700 EGP)")

conn.commit()
cur.close()
conn.close()

print("\nSUCCESS: Category cover updated and products added to 'الأعلام' successfully!")
