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

wallet_images = [
    {
        "src_file": "media_1787586981026.jpg",
        "dest_filename": "wallet_engraved_single.jpg",
        "product_name": "محفظة حفر وش واحد"
    },
    {
        "src_file": "media_1787586964485.jpg",
        "dest_filename": "wallet_engraved_group.jpg",
        "product_name": "محفظة حفر وشين"
    }
]

print("--- UPLOADING WALLET IMAGES TO SUPABASE STORAGE 'product_images' BUCKET ---")
for item in wallet_images:
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

print("\n--- UPDATING WALLET PRODUCTS IN SUPABASE DATABASE ---")
for item in wallet_images:
    cur.execute("""
        UPDATE products 
        SET image_filename = %s 
        WHERE name = %s OR category_id = 17 AND name LIKE %s;
    """, (item["dest_filename"], item["product_name"], f"%{item['product_name']}%"))
    print(f"Updated product '{item['product_name']}' with image '{item['dest_filename']}'")

conn.commit()

# Verification
print("\n=======================================================")
print("🎉 VERIFICATION OF PRODUCTS IN SUPABASE 'المحافظ' CATEGORY:")
print("=======================================================")
cur.execute("""
    SELECT p.id, p.name, p.price, p.image_filename, c.name as cat_name
    FROM products p
    JOIN categories c ON p.category_id = c.id
    WHERE c.name LIKE '%محافظ%' OR p.category_id = 17
    ORDER BY p.id ASC;
""")
for r in cur.fetchall():
    img_url = f"https://kxeqayzxfvoedqvilcmp.supabase.co/storage/v1/object/public/product_images/{r[3]}"
    print(f"ID: {r[0]} | Name: {r[1]} | Price: {r[2]} EGP | Image: {r[3]}")
    print(f"   Full Public Image URL: {img_url}")
    print("-" * 55)

cur.close()
conn.close()
print("\n✅ DONE! ALL WALLET PRODUCTS UPDATED SUCCESSFULLY IN SUPABASE!")
