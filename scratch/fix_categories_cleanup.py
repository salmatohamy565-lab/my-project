import sys
import io
import psycopg2

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

DATABASE_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

print("Connecting directly to PostgreSQL Database...")
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

# 1. Delete all old dummy "بروار" / "مسطرة" / "جامبو" products
cur.execute("DELETE FROM products WHERE name LIKE '%بروار%' OR name LIKE '%مسطرة%' OR name LIKE '%جامبو%';")
conn.commit()
print("Deleted old dummy products!")

# 2. Merge duplicate category pairs: (Old ID to remove, Target ID to keep)
merge_pairs = [
    (14, 15, "الأختام"), # 14 'اختام' -> 15 'الأختام'
    (11, 19, "الأقلام"), # 11 'اقلام' -> 19 'الأقلام'
    (13, 18, "الأعلام"), # 13 'اعلام' -> 18 'الأعلام'
    (8, 17, "المحافظ"),  # 8 'محافظ' -> 17 'المحافظ'
    (9, 16, "تيشيرتات"), # 9 'تيشرتات' -> 16 'تيشيرتات'
]

for old_id, new_id, final_name in merge_pairs:
    print(f"\nMerging Category ID {old_id} into ID {new_id} ({final_name})...")
    # Move products
    cur.execute("UPDATE products SET category_id = %s WHERE category_id = %s;", (new_id, old_id))
    # Move subcategories if any
    cur.execute("UPDATE subcategories SET category_id = %s WHERE category_id = %s;", (new_id, old_id))
    # Delete old duplicate category
    cur.execute("DELETE FROM categories WHERE id = %s;", (old_id,))
    # Ensure target category name is standardized
    cur.execute("UPDATE categories SET name = %s WHERE id = %s;", (final_name, new_id))
    conn.commit()
    print(f"Merged and cleaned ID {old_id} successfully!")

# Ensure other clean category names
standard_names = {
    3: "المجات",
    5: "الميداليات",
    6: "شهادات",
    1: "فوتوبلوك وبراويز",
    2: "ورقيات",
    4: "مستلزمات الأفراح",
    7: "تابلوهات",
    10: "دروع",
    12: "ستاند مكتب"
}

for cid, cname in standard_names.items():
    cur.execute("UPDATE categories SET name = %s WHERE id = %s;", (cname, cid))

conn.commit()

# Print clean category list with product count
cur.execute("SELECT id, name FROM categories ORDER BY id ASC;")
clean_cats = cur.fetchall()
print("\n=== CLEAN CATEGORIES IN SUPABASE ===")
for c in clean_cats:
    cur.execute("SELECT COUNT(*) FROM products WHERE category_id = %s;", (c[0],))
    p_count = cur.fetchone()[0]
    
    # Also check subcategories products
    cur.execute("""
        SELECT COUNT(*) FROM products p 
        JOIN subcategories s ON p.subcategory_id = s.id 
        WHERE s.category_id = %s;
    """, (c[0],))
    sub_p_count = cur.fetchone()[0]
    
    print(f"ID: {c[0]:2d} | Category: '{c[1]}'\t | Direct Products: {p_count} | SubCategory Products: {sub_p_count}")

# Print list of products per category for verification
print("\n=== ALL PRODUCTS BY CATEGORY IN SUPABASE ===")
for c in clean_cats:
    cur.execute("""
        SELECT p.id, p.name, p.price, p.description 
        FROM products p 
        LEFT JOIN subcategories s ON p.subcategory_id = s.id 
        WHERE p.category_id = %s OR s.category_id = %s 
        ORDER BY p.id ASC;
    """, (c[0], c[0]))
    prods = cur.fetchall()
    if prods:
        print(f"\n📁 Category: '{c[1]}' (ID: {c[0]})")
        for p in prods:
            print(f"   - Product #{p[0]}: {p[1]} | {p[2]} EGP")

cur.close()
conn.close()
print("\n🎉 SUPABASE DATABASE FULLY CLEANED & RE-ORGANIZED SUCCESSFULLY!")
