import sys
import psycopg2

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def main():
    print("Connecting to Supabase Database...")
    conn = psycopg2.connect(pooler_url)
    cur = conn.cursor()

    # 1. Create categories table
    print("Creating categories table...")
    cur.execute("""
        CREATE TABLE IF NOT EXISTS public.categories (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL UNIQUE,
            icon_name VARCHAR(100),
            image_url TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    """)

    # 2. Create subcategories table
    print("Creating subcategories table...")
    cur.execute("""
        CREATE TABLE IF NOT EXISTS public.subcategories (
            id SERIAL PRIMARY KEY,
            category_id INTEGER NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
            name VARCHAR(255) NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            UNIQUE(category_id, name)
        );
    """)

    # 3. Update products table
    print("Updating products table schema...")
    cur.execute("DELETE FROM public.products;")

    cur.execute("""
        ALTER TABLE public.products DROP COLUMN IF EXISTS category_id;
        ALTER TABLE public.products DROP COLUMN IF EXISTS subcategory_id;
    """)

    cur.execute("""
        ALTER TABLE public.products
        ADD COLUMN category_id INTEGER REFERENCES public.categories(id) ON DELETE CASCADE,
        ADD COLUMN subcategory_id INTEGER REFERENCES public.subcategories(id) ON DELETE CASCADE;
    """)

    # Add CHECK constraint: product must link to EITHER category_id OR subcategory_id
    cur.execute("""
        ALTER TABLE public.products DROP CONSTRAINT IF EXISTS product_category_subcategory_check;
        ALTER TABLE public.products ADD CONSTRAINT product_category_subcategory_check
        CHECK (
            (category_id IS NOT NULL AND subcategory_id IS NULL)
            OR
            (category_id IS NULL AND subcategory_id IS NOT NULL)
        );
    """)

    # 4. Enable RLS and add public SELECT policy
    for tbl in ['categories', 'subcategories', 'products']:
        cur.execute(f"ALTER TABLE public.{tbl} ENABLE ROW LEVEL SECURITY;")
        cur.execute(f"DROP POLICY IF EXISTS allow_public_select_{tbl} ON public.{tbl};")
        cur.execute(f"CREATE POLICY allow_public_select_{tbl} ON public.{tbl} FOR SELECT USING (true);")
        cur.execute(f"DROP POLICY IF EXISTS allow_all_{tbl} ON public.{tbl};")
        cur.execute(f"CREATE POLICY allow_all_{tbl} ON public.{tbl} FOR ALL USING (true) WITH CHECK (true);")

    # 5. Clear old categories and seed top-level categories
    cur.execute("TRUNCATE TABLE public.categories CASCADE;")

    all_categories = [
        "فوتوبلوك وبراويز",
        "ورقيات",
        "مجات",
        "مستلزمات الأفراح",
        "ميداليات",
        "شهادات",
        "تابلوهات",
        "محافظ",
        "تيشرتات",
        "دروع",
        "اقلام",
        "ستاند مكتب",
        "اعلام",
        "اختام"
    ]

    category_map = {}
    for cat in all_categories:
        cur.execute("INSERT INTO public.categories (name) VALUES (%s) RETURNING id;", (cat,))
        cat_id = cur.fetchone()[0]
        category_map[cat] = cat_id
        print(f"Inserted Category: '{cat}' -> ID: {cat_id}")

    # 6. Seed Subcategories for "فوتوبلوك وبراويز"
    frames_cat_id = category_map["فوتوبلوك وبراويز"]

    subcat_frames_map = {}
    frames_subcategories = ["بروار مسطرة", "بروار جامبو", "فوتوبلوك خشب"]
    for subcat in frames_subcategories:
        cur.execute("INSERT INTO public.subcategories (category_id, name) VALUES (%s, %s) RETURNING id;", (frames_cat_id, subcat))
        sub_id = cur.fetchone()[0]
        subcat_frames_map[subcat] = sub_id
        print(f"  Inserted Subcategory: '{subcat}' -> ID: {sub_id}")

    # 7. Seed Products for "فوتوبلوك وبراويز"
    products_to_insert = [
        # Subcategory: بروار مسطرة
        ("بروار مسطرة", "بروار مسطرة مقاس 10x15 سم", "إطار مسطرة كلاسيك مقاس 10x15 سم", 60.0),
        ("بروار مسطرة", "بروار مسطرة مقاس 15x20 سم", "إطار مسطرة كلاسيك مقاس 15x20 سم", 90.0),
        ("بروار مسطرة", "بروار مسطرة مقاس 20x30 سم", "إطار مسطرة كلاسيك مقاس 20x30 سم", 150.0),
        ("بروار مسطرة", "بروار مسطرة مقاس 30x40 سم", "إطار مسطرة كلاسيك مقاس 30x40 سم", 200.0),
        ("بروار مسطرة", "بروار مسطرة مقاس 40x50 سم", "إطار مسطرة كلاسيك مقاس 40x50 سم", 300.0),
        ("بروار مسطرة", "بروار مسطرة مقاس 50x60 سم", "إطار مسطرة كلاسيك مقاس 50x60 سم", 350.0),
        ("بروار مسطرة", "بروار مسطرة مقاس 50x70 سم", "إطار مسطرة كلاسيك مقاس 50x70 سم", 400.0),

        # Subcategory: بروار جامبو
        ("بروار جامبو", "بروار جامبو مقاس 15x20 سم", "إطار بروار جامبو بارز مقاس 15x20 سم", 130.0),
        ("بروار جامبو", "بروار جامبو مقاس 20x30 سم", "إطار بروار جامبو بارز مقاس 20x30 سم", 220.0),
        ("بروار جامبو", "بروار جامبو مقاس 30x40 سم", "إطار بروار جامبو بارز مقاس 30x40 سم", 280.0),
        ("بروار جامبو", "بروار جامبو مقاس 40x50 سم", "إطار بروار جامبو بارز مقاس 40x50 سم", 400.0),
        ("بروار جامبو", "بروار جامبو مقاس 50x60 سم", "إطار بروار جامبو بارز مقاس 50x60 سم", 450.0),
        ("بروار جامبو", "بروار جامبو مقاس 50x70 سم", "إطار بروار جامبو بارز مقاس 50x70 سم", 500.0),

        # Subcategory: فوتوبلوك خشب
        ("فوتوبلوك خشب", "فوتوبلوك خشب مقاس 15x20 سم", "فوتوبلوك خشب MDF مقاس 15x20 سم", 90.0),
        ("فوتوبلوك خشب", "فوتوبلوك خشب مقاس 20x30 سم", "فوتوبلوك خشب MDF مقاس 20x30 سم", 150.0),
        ("فوتوبلوك خشب", "فوتوبلوك خشب مقاس 30x40 سم", "فوتوبلوك خشب MDF مقاس 30x40 سم", 200.0),
        ("فوتوبلوك خشب", "فوتوبلوك خشب مقاس 40x50 سم", "فوتوبلوك خشب MDF مقاس 40x50 سم", 300.0),
        ("فوتوبلوك خشب", "فوتوبلوك خشب مقاس 50x60 سم", "فوتوبلوك خشب MDF مقاس 50x60 سم", 350.0),
        ("فوتوبلوك خشب", "فوتوبلوك خشب مقاس 50x70 سم", "فوتوبلوك خشب MDF مقاس 50x70 سم", 400.0),
        ("فوتوبلوك خشب", "فوتوبلوك خشب مقاس 60x90 سم", "فوتوبلوك خشب MDF مقاس 60x90 سم", 500.0),
    ]

    for subcat_name, name, desc, price in products_to_insert:
        sub_id = subcat_frames_map[subcat_name]
        cur.execute("""
            INSERT INTO public.products (name, description, price, subcategory_id)
            VALUES (%s, %s, %s, %s);
        """, (name, desc, price, sub_id))
        print(f"    Inserted Product: '{name}' ({price} EGP) -> subcategory_id: {sub_id}")

    # 8. Seed Subcategories for "ورقيات" (4 placeholder subcategories)
    paper_cat_id = category_map["ورقيات"]
    paper_subcategories = ["ورق دعايا", "كروت شخصية", "روشتات", "منيوهات"]
    for subcat in paper_subcategories:
        cur.execute("INSERT INTO public.subcategories (category_id, name) VALUES (%s, %s) RETURNING id;", (paper_cat_id, subcat))
        sub_id = cur.fetchone()[0]
        print(f"  Inserted Subcategory for ورقيات: '{subcat}' -> ID: {sub_id}")

    conn.commit()
    cur.close()
    conn.close()
    print("\nSUCCESS: Setup and seeding of Categories, Subcategories, and Products completed successfully!")

if __name__ == '__main__':
    main()
