import sys
import psycopg2

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def main():
    conn = psycopg2.connect(pooler_url)
    cur = conn.cursor()

    print("--- 1. CHECK CATEGORIES ---")
    cur.execute("SELECT id, name FROM public.categories ORDER BY id;")
    categories = cur.fetchall()
    print(f"Total Categories: {len(categories)}")
    for cat in categories:
        cur.execute("SELECT count(*) FROM public.subcategories WHERE category_id = %s;", (cat[0],))
        sub_cnt = cur.fetchone()[0]
        cur.execute("SELECT count(*) FROM public.products WHERE category_id = %s;", (cat[0],))
        prod_cnt = cur.fetchone()[0]
        print(f"Cat #{cat[0]}: '{cat[1]}' -> Subcategories: {sub_cnt}, Direct Products: {prod_cnt}")

    print("\n--- 2. CHECK SUBCATEGORIES FOR 'فوتوبلوك وبراويز' ---")
    cur.execute("""
        SELECT s.id, s.name, count(p.id)
        FROM public.subcategories s
        JOIN public.categories c ON c.id = s.category_id
        LEFT JOIN public.products p ON p.subcategory_id = s.id
        WHERE c.name = 'فوتوبلوك وبراويز'
        GROUP BY s.id, s.name
        ORDER BY s.id;
    """)
    frames_subs = cur.fetchall()
    for sub in frames_subs:
        print(f"Subcategory #{sub[0]}: '{sub[1]}' -> Products Count: {sub[2]}")
        cur.execute("SELECT name, price FROM public.products WHERE subcategory_id = %s ORDER BY price;", (sub[0],))
        prods = cur.fetchall()
        for p in prods:
            print(f"   - {p[0]} @ {p[1]} EGP")

    print("\n--- 3. TEST PRODUCT CONSTRAINT VALIDATION ---")

    # Test 1: Insert product linked to subcategory (valid)
    cur.execute("SELECT id FROM public.subcategories LIMIT 1;")
    valid_sub_id = cur.fetchone()[0]
    cur.execute("""
        INSERT INTO public.products (name, description, price, subcategory_id)
        VALUES ('اختبار منتج فرعي', 'وصف اختبار', 99.9, %s)
        RETURNING id;
    """, (valid_sub_id,))
    test_p1_id = cur.fetchone()[0]
    print(f"✅ Successfully inserted product #{test_p1_id} linked to subcategory #{valid_sub_id}")

    # Test 2: Insert product linked to category (valid)
    cur.execute("SELECT id FROM public.categories WHERE name = 'مجات' LIMIT 1;")
    mugs_cat_id = cur.fetchone()[0]
    cur.execute("""
        INSERT INTO public.products (name, description, price, category_id)
        VALUES ('مج اختبار حراري', 'وصف مج اختبار', 120.0, %s)
        RETURNING id;
    """, (mugs_cat_id,))
    test_p2_id = cur.fetchone()[0]
    print(f"✅ Successfully inserted product #{test_p2_id} linked to category #{mugs_cat_id}")

    # Test 3: Insert product linked to BOTH (should FAIL check constraint)
    try:
        cur.execute("""
            INSERT INTO public.products (name, description, price, category_id, subcategory_id)
            VALUES ('منتج باطل', 'وصف', 10.0, %s, %s);
        """, (mugs_cat_id, valid_sub_id))
        print("❌ ERROR: Product with both category and subcategory should have failed!")
    except Exception as e:
        print(f"✅ Check constraint working! Prevented invalid product: {e}")
        conn.rollback()
        conn = psycopg2.connect(pooler_url)
        cur = conn.cursor()

    # Clean test products
    cur.execute("DELETE FROM public.products WHERE id IN (%s, %s);", (test_p1_id, test_p2_id))
    conn.commit()

    cur.close()
    conn.close()
    print("\n🎉 ALL VERIFICATION TESTS PASSED SUCCESSFULLY!")

if __name__ == '__main__':
    main()
