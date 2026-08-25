import psycopg2
import sys

sys.stdout.reconfigure(encoding='utf-8')

pooler_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"

def test_add_product():
    conn = psycopg2.connect(pooler_url)
    conn.autocommit = True
    cur = conn.cursor()

    print("\n--- TEST: Insert product into category 'braweez' (براويز) ---")
    cur.execute("""
        INSERT INTO public.products (name, description, price, category_id, created_at)
        VALUES ('salma', 'sahgujdejkgymalak', 550.0, 'braweez', NOW())
        RETURNING id, name, price, category_id;
    """)
    prod_id, name, price, cat = cur.fetchone()
    print(f"[OK] Successfully saved product #{prod_id}: '{name}' ({price} EGP) in category '{cat}'!")

    # Clean up test row
    cur.execute("DELETE FROM public.products WHERE id = %s;", (prod_id,))
    print(f"[OK] Cleaned test row #{prod_id}")

    cur.close()
    conn.close()

if __name__ == '__main__':
    test_add_product()
