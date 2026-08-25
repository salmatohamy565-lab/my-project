import sys
import io
import psycopg2

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# 1. Delete the new products we added earlier (IDs 67 to 71 or names like 'شهادة تقدير...')
print("1. Cleaning up newly added duplicate product rows...")
cur.execute("""
    DELETE FROM products 
    WHERE name IN (
        'شهادة تقدير كحلي وذهبي فاخرة',
        'شهادة تقدير وتفوق أزرق كلاسيك',
        'شهادة تقدير مذهبة بالشريط الأحمر',
        'شهادة تخرج وتكريم زمردي وذهبي',
        'شهادة خبرة وكفاءة أنيقة'
    );
""")
deleted_count = cur.rowcount
print(f"Deleted {deleted_count} newly created product rows.")

# Delete subcategory 'نماذج شهادات تقدير' if exists
cur.execute("DELETE FROM subcategories WHERE name = 'نماذج شهادات تقدير';")

# 2. Update existing certificate products with the uploaded images!
# Map of existing product names to their uploaded image filename
image_updates = [
    ("ورق عادى", "cert_navy_gold.jpg"),
    ("ورق مقوى", "cert_blue_classic.jpg"),
    ("ورق جلوس 180 جرام", "cert_red_gold.jpg"),
    ("ورق جلوس 200 جرام", "cert_emerald_gold.jpg"),
    ("ورق جلوس 260 جرام", "cert_brown_gold.jpg"),
    ("ورق جلوس مضلع", "cert_navy_gold.jpg"),
]

print("\n2. Updating images on existing certificate products...")
for prod_name, img_file in image_updates:
    cur.execute("""
        UPDATE products 
        SET image_filename = %s
        WHERE name = %s;
    """, (img_file, prod_name))
    print(f"Updated '{prod_name}' with image '{img_file}'")

conn.commit()

# 3. Verification query
print("\n=======================================================")
print("🎉 CURRENT CERTIFICATE PRODUCTS IN SUPABASE DATABASE:")
print("=======================================================")
cur.execute("""
    SELECT p.id, p.name, p.price, p.image_filename, c.name as cat_name, s.name as subcat_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN subcategories s ON p.subcategory_id = s.id
    WHERE p.category_id = 6 OR p.subcategory_id = 8 OR c.name LIKE '%شهاد%' OR s.name LIKE '%جلوس%'
    ORDER BY p.id ASC;
""")
for r in cur.fetchall():
    print(f"ID: {r[0]} | Name: {r[1]} | Price: {r[2]} EGP | Image: {r[3]} | Cat: {r[4]} | SubCat: {r[5]}")

cur.close()
conn.close()
print("\n✅ SUCCESS! All existing certificate products now have their images updated directly!")
