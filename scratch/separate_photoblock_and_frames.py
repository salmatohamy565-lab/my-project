import sys
import psycopg2

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(pooler_url)
cur = conn.cursor()

print("--- SEPARATING PHOTOBLOCK AND FRAMES CATEGORIES ---")

# 1. Rename Category #1 to 'فوتوبلوك'
cur.execute("UPDATE public.categories SET name = 'فوتوبلوك', image_url = 'frames.jpg' WHERE id = 1;")
print("Renamed Category #1 to 'فوتوبلوك'")

# 2. Check if Category 'براويز' exists, otherwise create it
cur.execute("SELECT id FROM public.categories WHERE name = 'براويز';")
row = cur.fetchone()
if row:
    frames_cat_id = row[0]
    print(f"Category 'براويز' already exists with ID #{frames_cat_id}")
else:
    cur.execute("INSERT INTO public.categories (name, image_url) VALUES ('براويز', 'frames.jpg') RETURNING id;")
    frames_cat_id = cur.fetchone()[0]
    print(f"Created new Category 'براويز' with ID #{frames_cat_id}")

# 3. Move subcategories 'بروار مسطرة' and 'بروار جامبو' to 'براويز' (Category ID frames_cat_id)
cur.execute("""
    UPDATE public.subcategories
    SET category_id = %s
    WHERE name IN ('بروار مسطرة', 'بروار جامبو');
""", (frames_cat_id,))
print(f"Moved subcategories 'بروار مسطرة' and 'بروار جامبو' to Category 'براويز' (ID #{frames_cat_id})")

# 4. Check subcategories under 'فوتوبلوك'
cur.execute("SELECT id, name FROM public.subcategories WHERE category_id = 1;")
print("Subcategories under 'فوتوبلوك':", cur.fetchall())

# 5. Check subcategories under 'براويز'
cur.execute("SELECT id, name FROM public.subcategories WHERE category_id = %s;", (frames_cat_id,))
print("Subcategories under 'براويز':", cur.fetchall())

conn.commit()
cur.close()
conn.close()

print("\nSUCCESS: 'فوتوبلوك' and 'براويز' separated into two distinct categories successfully!")
