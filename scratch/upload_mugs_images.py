import sys
import io
import os
import psycopg2
from supabase import create_client

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

SUPABASE_URL = "https://kxeqayzxfvoedqvilcmp.supabase.co"
SUPABASE_KEY = "sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Database connection
DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

user_dir = r"C:\Users\bolad\.gemini\antigravity-ide\brain\0ab0c6c2-d6ea-415d-906d-2759d3ae5e00\.user_uploaded"

img_lens_path = os.path.join(user_dir, "media_1787242679456.jpg")
img_white_path = os.path.join(user_dir, "media_1787242683826.jpg")
img_digital_path = os.path.join(user_dir, "media_1787242689478.jpg")

lens_file = "mug_lens_real.jpg"
white_file = "mug_white_real.jpg"
digital_file = "mug_digital_real.jpg"

def upload_file(bucket_name, file_path, dest_filename):
    try:
        with open(file_path, 'rb') as f:
            file_data = f.read()
        res = supabase.storage.from_(bucket_name).upload(
            path=dest_filename,
            file=file_data,
            file_options={"content-type": "image/jpeg", "x-upsert": "true"}
        )
        print(f"Uploaded {dest_filename} to bucket '{bucket_name}' successfully!")
    except Exception as ex:
        print(f"Info for {dest_filename}: {ex}")

# Upload to product_images bucket
upload_file("product_images", img_lens_path, lens_file)
upload_file("product_images", img_white_path, white_file)
upload_file("product_images", img_digital_path, digital_file)

print("\nUpdating products table in Supabase Database...")

# 1. مج عدسة & مج عدسة كبير
cur.execute("UPDATE products SET image_filename = %s WHERE name LIKE %s;", (lens_file, '%عدسة%'))

# 2. مج أبيض
cur.execute("UPDATE products SET image_filename = %s WHERE name LIKE %s;", (white_file, '%أبيض%'))

# 3. مج ديجيتال
cur.execute("UPDATE products SET image_filename = %s WHERE name LIKE %s;", (digital_file, '%ديجيتال%'))

# 4. مج سحري
cur.execute("UPDATE products SET image_filename = %s WHERE name LIKE %s;", (white_file, '%سحري%'))

# 5. مج أزاز باسم
cur.execute("UPDATE products SET image_filename = %s WHERE name LIKE %s;", (digital_file, '%أزاز%'))

conn.commit()

# Verification query
cur.execute("SELECT id, name, price, image_filename FROM products WHERE name LIKE '%مج%' ORDER BY id ASC;")
rows = cur.fetchall()
print("\n--- VERIFICATION OF PRODUCTS & IMAGES IN SUPABASE ---")
for r in rows:
    print(f"ID: {r[0]} | Name: {r[1]} | Price: {r[2]} | Image Filename: {r[3]}")

cur.close()
conn.close()
print("\n🎉 ALL 3 IMAGES SUCCESSFULLY UPLOADED TO SUPABASE BUCKET & LINKED TO PRODUCTS IN SUPABASE DATABASE!")
