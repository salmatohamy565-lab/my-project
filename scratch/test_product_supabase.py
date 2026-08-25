import psycopg2
import sys

sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def test_product_flow():
    print("Connecting to Supabase Database...")
    conn = psycopg2.connect(pooler_url)
    conn.autocommit = True
    cur = conn.cursor()

    print("\n--- TEST 1: Insert New Product into public.products ---")
    cur.execute("""
        INSERT INTO public.products (name, description, price, category_id, created_at)
        VALUES ('منتج تجريبي جديد', 'وصف المنتج التجريبي', 450.0, 'tshirts', NOW())
        RETURNING id, name, price;
    """)
    prod_id, name, price = cur.fetchone()
    print(f"[OK] Created test product #{prod_id}: '{name}' at {price} EGP")

    print("\n--- TEST 2: Update Product in public.products ---")
    cur.execute("""
        UPDATE public.products
        SET price = 500.0, description = 'تم تحديث السعر والوصف'
        WHERE id = %s
        RETURNING id, price, description;
    """, (prod_id,))
    up_id, new_price, new_desc = cur.fetchone()
    print(f"[OK] Updated product #{up_id} to price: {new_price} EGP, desc: '{new_desc}'")

    print("\n--- TEST 3: Cleanup Test Product ---")
    cur.execute("DELETE FROM public.products WHERE id = %s;", (prod_id,))
    print(f"[OK] Cleaned up test product #{prod_id}")

    print("\nALL PRODUCT SUPABASE TESTS PASSED SUCCESSFULLY!")
    cur.close()
    conn.close()

if __name__ == '__main__':
    test_product_flow()
