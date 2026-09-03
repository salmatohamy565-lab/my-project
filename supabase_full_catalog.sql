
-- ====================================================================
-- BOLA DESIGNS - COMPLETE COMPREHENSIVE SUPABASE EXTENSION SCHEMA & DATA
-- Includes:
-- 1. categories table & subcategories table
-- 2. files table (User files & admin file exchanges)
-- 3. shared_files table
-- 4. products table schema updates (subcategory_id, is_offer, offer fields)
-- 5. Complete Catalog Seeding (All 14 Categories + All Subcategories + All Products)
-- 6. Row Level Security and Permissions for ALL tables
-- ====================================================================

-- 1. Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    icon_name VARCHAR(100),
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Subcategories Table
CREATE TABLE IF NOT EXISTS public.subcategories (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(category_id, name)
);

-- 3. Files Table
CREATE TABLE IF NOT EXISTS public.files (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES public.users(id) ON DELETE CASCADE,
    recipient_id INTEGER REFERENCES public.users(id) ON DELETE SET NULL,
    filename VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Shared Files Table
CREATE TABLE IF NOT EXISTS public.shared_files (
    id SERIAL PRIMARY KEY,
    sender_id INT NULL,
    sender_name VARCHAR(255) NULL,
    recipient_id INT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(50) DEFAULT 'document',
    archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Update products table with all required columns
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS subcategory_id INTEGER REFERENCES public.subcategories(id) ON DELETE SET NULL;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_offer BOOLEAN DEFAULT FALSE;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS original_price DOUBLE PRECISION;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS offer_discount VARCHAR(50);
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS offer_details TEXT;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 6. Enable RLS and add public access policies for all new tables


ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'categories' AND policyname = 'Allow public access to categories'
    ) THEN
        CREATE POLICY "Allow public access to categories" ON public.categories FOR ALL TO public USING (true) WITH CHECK (true);
    END IF;
END
$$;
GRANT ALL ON TABLE public.categories TO anon, authenticated, service_role;


ALTER TABLE public.subcategories ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'subcategories' AND policyname = 'Allow public access to subcategories'
    ) THEN
        CREATE POLICY "Allow public access to subcategories" ON public.subcategories FOR ALL TO public USING (true) WITH CHECK (true);
    END IF;
END
$$;
GRANT ALL ON TABLE public.subcategories TO anon, authenticated, service_role;


ALTER TABLE public.files ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'files' AND policyname = 'Allow public access to files'
    ) THEN
        CREATE POLICY "Allow public access to files" ON public.files FOR ALL TO public USING (true) WITH CHECK (true);
    END IF;
END
$$;
GRANT ALL ON TABLE public.files TO anon, authenticated, service_role;


ALTER TABLE public.shared_files ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'shared_files' AND policyname = 'Allow public access to shared_files'
    ) THEN
        CREATE POLICY "Allow public access to shared_files" ON public.shared_files FOR ALL TO public USING (true) WITH CHECK (true);
    END IF;
END
$$;
GRANT ALL ON TABLE public.shared_files TO anon, authenticated, service_role;


-- ==================== CATEGORIES ====================
INSERT INTO public.categories (id, name) VALUES (1, 'فوتوبلوك وبراويز') ON CONFLICT (id) DO UPDATE SET name = 'فوتوبلوك وبراويز';
INSERT INTO public.categories (id, name) VALUES (2, 'ورقيات') ON CONFLICT (id) DO UPDATE SET name = 'ورقيات';
INSERT INTO public.categories (id, name) VALUES (3, 'مجات') ON CONFLICT (id) DO UPDATE SET name = 'مجات';
INSERT INTO public.categories (id, name) VALUES (4, 'مستلزمات الأفراح') ON CONFLICT (id) DO UPDATE SET name = 'مستلزمات الأفراح';
INSERT INTO public.categories (id, name) VALUES (5, 'ميداليات') ON CONFLICT (id) DO UPDATE SET name = 'ميداليات';
INSERT INTO public.categories (id, name) VALUES (6, 'شهادات') ON CONFLICT (id) DO UPDATE SET name = 'شهادات';
INSERT INTO public.categories (id, name) VALUES (7, 'تابلوهات') ON CONFLICT (id) DO UPDATE SET name = 'تابلوهات';
INSERT INTO public.categories (id, name) VALUES (8, 'محافظ') ON CONFLICT (id) DO UPDATE SET name = 'محافظ';
INSERT INTO public.categories (id, name) VALUES (9, 'تيشرتات') ON CONFLICT (id) DO UPDATE SET name = 'تيشرتات';
INSERT INTO public.categories (id, name) VALUES (10, 'دروع') ON CONFLICT (id) DO UPDATE SET name = 'دروع';
INSERT INTO public.categories (id, name) VALUES (11, 'اقلام') ON CONFLICT (id) DO UPDATE SET name = 'اقلام';
INSERT INTO public.categories (id, name) VALUES (12, 'ستاند مكتب') ON CONFLICT (id) DO UPDATE SET name = 'ستاند مكتب';
INSERT INTO public.categories (id, name) VALUES (13, 'اعلام') ON CONFLICT (id) DO UPDATE SET name = 'اعلام';
INSERT INTO public.categories (id, name) VALUES (14, 'اختام') ON CONFLICT (id) DO UPDATE SET name = 'اختام';
SELECT setval('categories_id_seq', COALESCE((SELECT MAX(id) FROM categories), 1));


-- ==================== SUBCATEGORIES ====================
INSERT INTO public.subcategories (id, category_id, name) VALUES (1, 1, 'بروار مسطرة') ON CONFLICT (id) DO UPDATE SET name = 'بروار مسطرة', category_id = 1;
INSERT INTO public.subcategories (id, category_id, name) VALUES (2, 1, 'بروار جامبو') ON CONFLICT (id) DO UPDATE SET name = 'بروار جامبو', category_id = 1;
INSERT INTO public.subcategories (id, category_id, name) VALUES (3, 1, 'فوتوبلوك خشب') ON CONFLICT (id) DO UPDATE SET name = 'فوتوبلوك خشب', category_id = 1;
INSERT INTO public.subcategories (id, category_id, name) VALUES (4, 2, 'ورق دعايا') ON CONFLICT (id) DO UPDATE SET name = 'ورق دعايا', category_id = 2;
INSERT INTO public.subcategories (id, category_id, name) VALUES (5, 2, 'كروت شخصية') ON CONFLICT (id) DO UPDATE SET name = 'كروت شخصية', category_id = 2;
INSERT INTO public.subcategories (id, category_id, name) VALUES (6, 2, 'روشتات') ON CONFLICT (id) DO UPDATE SET name = 'روشتات', category_id = 2;
INSERT INTO public.subcategories (id, category_id, name) VALUES (7, 2, 'منيوهات') ON CONFLICT (id) DO UPDATE SET name = 'منيوهات', category_id = 2;
SELECT setval('subcategories_id_seq', COALESCE((SELECT MAX(id) FROM subcategories), 1));


-- ==================== ALL PRODUCTS ====================
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (1, 'بروار مسطرة مقاس 10x15 سم', 'إطار مسطرة كلاسيك مقاس 10x15 سم', 60.0, NULL, 1, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'بروار مسطرة مقاس 10x15 سم',
    description = 'إطار مسطرة كلاسيك مقاس 10x15 سم',
    price = 60.0,
    category_id = NULL,
    subcategory_id = 1,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (2, 'بروار مسطرة مقاس 15x20 سم', 'إطار مسطرة كلاسيك مقاس 15x20 سم', 90.0, NULL, 1, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'بروار مسطرة مقاس 15x20 سم',
    description = 'إطار مسطرة كلاسيك مقاس 15x20 سم',
    price = 90.0,
    category_id = NULL,
    subcategory_id = 1,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (3, 'بروار مسطرة مقاس 20x30 سم', 'إطار مسطرة كلاسيك مقاس 20x30 سم', 150.0, NULL, 1, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'بروار مسطرة مقاس 20x30 سم',
    description = 'إطار مسطرة كلاسيك مقاس 20x30 سم',
    price = 150.0,
    category_id = NULL,
    subcategory_id = 1,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (4, 'بروار مسطرة مقاس 30x40 سم', 'إطار مسطرة كلاسيك مقاس 30x40 سم', 200.0, NULL, 1, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'بروار مسطرة مقاس 30x40 سم',
    description = 'إطار مسطرة كلاسيك مقاس 30x40 سم',
    price = 200.0,
    category_id = NULL,
    subcategory_id = 1,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (5, 'بروار مسطرة مقاس 40x50 سم', 'إطار مسطرة كلاسيك مقاس 40x50 سم', 300.0, NULL, 1, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'بروار مسطرة مقاس 40x50 سم',
    description = 'إطار مسطرة كلاسيك مقاس 40x50 سم',
    price = 300.0,
    category_id = NULL,
    subcategory_id = 1,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (6, 'بروار مسطرة مقاس 50x60 سم', 'إطار مسطرة كلاسيك مقاس 50x60 سم', 350.0, NULL, 1, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'بروار مسطرة مقاس 50x60 سم',
    description = 'إطار مسطرة كلاسيك مقاس 50x60 سم',
    price = 350.0,
    category_id = NULL,
    subcategory_id = 1,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (7, 'بروار مسطرة مقاس 50x70 سم', 'إطار مسطرة كلاسيك مقاس 50x70 سم', 400.0, NULL, 1, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'بروار مسطرة مقاس 50x70 سم',
    description = 'إطار مسطرة كلاسيك مقاس 50x70 سم',
    price = 400.0,
    category_id = NULL,
    subcategory_id = 1,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (8, 'بروار جامبو مقاس 15x20 سم', 'إطار بروار جامبو بارز مقاس 15x20 سم', 130.0, NULL, 2, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'بروار جامبو مقاس 15x20 سم',
    description = 'إطار بروار جامبو بارز مقاس 15x20 سم',
    price = 130.0,
    category_id = NULL,
    subcategory_id = 2,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (9, 'بروار جامبو مقاس 20x30 سم', 'إطار بروار جامبو بارز مقاس 20x30 سم', 220.0, NULL, 2, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'بروار جامبو مقاس 20x30 سم',
    description = 'إطار بروار جامبو بارز مقاس 20x30 سم',
    price = 220.0,
    category_id = NULL,
    subcategory_id = 2,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (10, 'بروار جامبو مقاس 30x40 سم', 'إطار بروار جامبو بارز مقاس 30x40 سم', 280.0, NULL, 2, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'بروار جامبو مقاس 30x40 سم',
    description = 'إطار بروار جامبو بارز مقاس 30x40 سم',
    price = 280.0,
    category_id = NULL,
    subcategory_id = 2,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (11, 'بروار جامبو مقاس 40x50 سم', 'إطار بروار جامبو بارز مقاس 40x50 سم', 400.0, NULL, 2, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'بروار جامبو مقاس 40x50 سم',
    description = 'إطار بروار جامبو بارز مقاس 40x50 سم',
    price = 400.0,
    category_id = NULL,
    subcategory_id = 2,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (12, 'بروار جامبو مقاس 50x60 سم', 'إطار بروار جامبو بارز مقاس 50x60 سم', 450.0, NULL, 2, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'بروار جامبو مقاس 50x60 سم',
    description = 'إطار بروار جامبو بارز مقاس 50x60 سم',
    price = 450.0,
    category_id = NULL,
    subcategory_id = 2,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (13, 'بروار جامبو مقاس 50x70 سم', 'إطار بروار جامبو بارز مقاس 50x70 سم', 500.0, NULL, 2, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'بروار جامبو مقاس 50x70 سم',
    description = 'إطار بروار جامبو بارز مقاس 50x70 سم',
    price = 500.0,
    category_id = NULL,
    subcategory_id = 2,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (14, 'فوتوبلوك خشب مقاس 15x20 سم', 'فوتوبلوك خشب MDF مقاس 15x20 سم', 90.0, NULL, 3, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'فوتوبلوك خشب مقاس 15x20 سم',
    description = 'فوتوبلوك خشب MDF مقاس 15x20 سم',
    price = 90.0,
    category_id = NULL,
    subcategory_id = 3,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (15, 'فوتوبلوك خشب مقاس 20x30 سم', 'فوتوبلوك خشب MDF مقاس 20x30 سم', 150.0, NULL, 3, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'فوتوبلوك خشب مقاس 20x30 سم',
    description = 'فوتوبلوك خشب MDF مقاس 20x30 سم',
    price = 150.0,
    category_id = NULL,
    subcategory_id = 3,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (16, 'فوتوبلوك خشب مقاس 30x40 سم', 'فوتوبلوك خشب MDF مقاس 30x40 سم', 200.0, NULL, 3, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'فوتوبلوك خشب مقاس 30x40 سم',
    description = 'فوتوبلوك خشب MDF مقاس 30x40 سم',
    price = 200.0,
    category_id = NULL,
    subcategory_id = 3,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (17, 'فوتوبلوك خشب مقاس 40x50 سم', 'فوتوبلوك خشب MDF مقاس 40x50 سم', 300.0, NULL, 3, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'فوتوبلوك خشب مقاس 40x50 سم',
    description = 'فوتوبلوك خشب MDF مقاس 40x50 سم',
    price = 300.0,
    category_id = NULL,
    subcategory_id = 3,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (18, 'فوتوبلوك خشب مقاس 50x60 سم', 'فوتوبلوك خشب MDF مقاس 50x60 سم', 350.0, NULL, 3, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'فوتوبلوك خشب مقاس 50x60 سم',
    description = 'فوتوبلوك خشب MDF مقاس 50x60 سم',
    price = 350.0,
    category_id = NULL,
    subcategory_id = 3,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (19, 'فوتوبلوك خشب مقاس 50x70 سم', 'فوتوبلوك خشب MDF مقاس 50x70 سم', 400.0, NULL, 3, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'فوتوبلوك خشب مقاس 50x70 سم',
    description = 'فوتوبلوك خشب MDF مقاس 50x70 سم',
    price = 400.0,
    category_id = NULL,
    subcategory_id = 3,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (20, 'فوتوبلوك خشب مقاس 60x90 سم', 'فوتوبلوك خشب MDF مقاس 60x90 سم', 500.0, NULL, 3, 'frames.jpg', 'frames.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'فوتوبلوك خشب مقاس 60x90 سم',
    description = 'فوتوبلوك خشب MDF مقاس 60x90 سم',
    price = 500.0,
    category_id = NULL,
    subcategory_id = 3,
    image_filename = 'frames.jpg',
    image_url = 'frames.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (21, 'كروت شخصية فاخرة (1000 كارت)', 'كروت شخصية وجهين سلوفان كوشيه 350 جرام', 350.0, 2, NULL, 'tableau_desk_wall_collage.jpg', 'tableau_desk_wall_collage.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'كروت شخصية فاخرة (1000 كارت)',
    description = 'كروت شخصية وجهين سلوفان كوشيه 350 جرام',
    price = 350.0,
    category_id = 2,
    subcategory_id = NULL,
    image_filename = 'tableau_desk_wall_collage.jpg',
    image_url = 'tableau_desk_wall_collage.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (22, 'فلاير دعائي مقاس A5 (1000 فلاير)', 'طباعة فلاير دعاية وإعلان ألوان وجهين كوشيه فاخر', 650.0, 2, NULL, 'tableau_desk_wall_collage.jpg', 'tableau_desk_wall_collage.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'فلاير دعائي مقاس A5 (1000 فلاير)',
    description = 'طباعة فلاير دعاية وإعلان ألوان وجهين كوشيه فاخر',
    price = 650.0,
    category_id = 2,
    subcategory_id = NULL,
    image_filename = 'tableau_desk_wall_collage.jpg',
    image_url = 'tableau_desk_wall_collage.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (23, 'روشتات طبية (10 دفاتر)', 'دفاتر روشتات طبية مخصصة للعيادات والمراكز', 450.0, 2, NULL, 'tableau_desk_wall_collage.jpg', 'tableau_desk_wall_collage.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'روشتات طبية (10 دفاتر)',
    description = 'دفاتر روشتات طبية مخصصة للعيادات والمراكز',
    price = 450.0,
    category_id = 2,
    subcategory_id = NULL,
    image_filename = 'tableau_desk_wall_collage.jpg',
    image_url = 'tableau_desk_wall_collage.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (24, 'مج أبيض كلاسيك', 'مج سيراميك فاخر أبيض للطباعة الحرارية عالية الدقة', 90.0, 3, NULL, 'family_mug.jpg', 'family_mug.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'مج أبيض كلاسيك',
    description = 'مج سيراميك فاخر أبيض للطباعة الحرارية عالية الدقة',
    price = 90.0,
    category_id = 3,
    subcategory_id = NULL,
    image_filename = 'family_mug.jpg',
    image_url = 'family_mug.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (25, 'مج سحري أسود مط', 'مج سحري يتغير لونه بالحرارة ليكشف عن التصميم عند وضع المشروب الساخن', 140.0, 3, NULL, 'magic_mug.jpg', 'magic_mug.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'مج سحري أسود مط',
    description = 'مج سحري يتغير لونه بالحرارة ليكشف عن التصميم عند وضع المشروب الساخن',
    price = 140.0,
    category_id = 3,
    subcategory_id = NULL,
    image_filename = 'magic_mug.jpg',
    image_url = 'magic_mug.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (26, 'مج ملون من الداخل واليد', 'مج سيراميك أنيق بألوان متعددة من الداخل مع يد ملونة مميزة', 110.0, 3, NULL, 'inner_color_mug.jpg', 'inner_color_mug.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'مج ملون من الداخل واليد',
    description = 'مج سيراميك أنيق بألوان متعددة من الداخل مع يد ملونة مميزة',
    price = 110.0,
    category_id = 3,
    subcategory_id = NULL,
    image_filename = 'inner_color_mug.jpg',
    image_url = 'inner_color_mug.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (27, 'مج مضيء فسفوري', 'مج مميز بإطار مضيء في الظلام وتأثيرات بصرية راقية', 130.0, 3, NULL, 'luminous_mug.jpg', 'luminous_mug.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'مج مضيء فسفوري',
    description = 'مج مميز بإطار مضيء في الظلام وتأثيرات بصرية راقية',
    price = 130.0,
    category_id = 3,
    subcategory_id = NULL,
    image_filename = 'luminous_mug.jpg',
    image_url = 'luminous_mug.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (28, 'روب عروسة ستان مطرز', 'روب ستان فاخر للعروسة تطريز يدوي مخصص بالاسم والتاريخ', 350.0, 4, NULL, 'wedding_robe.jpg', 'wedding_robe.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'روب عروسة ستان مطرز',
    description = 'روب ستان فاخر للعروسة تطريز يدوي مخصص بالاسم والتاريخ',
    price = 350.0,
    category_id = 4,
    subcategory_id = NULL,
    image_filename = 'wedding_robe.jpg',
    image_url = 'wedding_robe.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (29, 'طارة شبكة ومنديل كتب كتاب هاند ميد', 'طارة خشبية أنيقة مكسوة بالتل والورد مع منديل كتب كتاب حرير', 280.0, 4, NULL, 'wedding_hoop.jpg', 'wedding_hoop.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'طارة شبكة ومنديل كتب كتاب هاند ميد',
    description = 'طارة خشبية أنيقة مكسوة بالتل والورد مع منديل كتب كتاب حرير',
    price = 280.0,
    category_id = 4,
    subcategory_id = NULL,
    image_filename = 'wedding_hoop.jpg',
    image_url = 'wedding_hoop.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (30, 'جيست بوك أفراح خشب ليزر', 'دفتر تهنئة خشبي فاخر حفر ليزر مع صفحات مخصصة لكتابة ذكريات الفرح', 320.0, 4, NULL, 'guest_book.jpg', 'guest_book.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'جيست بوك أفراح خشب ليزر',
    description = 'دفتر تهنئة خشبي فاخر حفر ليزر مع صفحات مخصصة لكتابة ذكريات الفرح',
    price = 320.0,
    category_id = 4,
    subcategory_id = NULL,
    image_filename = 'guest_book.jpg',
    image_url = 'guest_book.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (31, 'شوكة وسكينة كيك فرح مخصصة', 'طقم تقطيع تورتة فرح مطلي ومزين بالاسم وحفر ليزر راقي', 200.0, 4, NULL, 'cake_set.jpg', 'cake_set.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'شوكة وسكينة كيك فرح مخصصة',
    description = 'طقم تقطيع تورتة فرح مطلي ومزين بالاسم وحفر ليزر راقي',
    price = 200.0,
    category_id = 4,
    subcategory_id = NULL,
    image_filename = 'cake_set.jpg',
    image_url = 'cake_set.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (32, 'ميدالية خشب حفر وجهين', 'ميدالية خشب طبيعي فاخر حفر ليزر بالاسم أو الصورة وجهين', 45.0, 5, NULL, 'keychain_wood.jpg', 'keychain_wood.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'ميدالية خشب حفر وجهين',
    description = 'ميدالية خشب طبيعي فاخر حفر ليزر بالاسم أو الصورة وجهين',
    price = 45.0,
    category_id = 5,
    subcategory_id = NULL,
    image_filename = 'keychain_wood.jpg',
    image_url = 'keychain_wood.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (33, 'ميدالية أكريليك شفاف فاخرة', 'ميدالية أكريليك عالي الشفافية مع طباعة ديجيتال ألوان ضد الخدش', 50.0, 5, NULL, 'keychain_acrylic.jpg', 'keychain_acrylic.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'ميدالية أكريليك شفاف فاخرة',
    description = 'ميدالية أكريليك عالي الشفافية مع طباعة ديجيتال ألوان ضد الخدش',
    price = 50.0,
    category_id = 5,
    subcategory_id = NULL,
    image_filename = 'keychain_acrylic.jpg',
    image_url = 'keychain_acrylic.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (34, 'ميدالية معدن مطلية بالاسم', 'ميدالية معدنية ثقيلة ومقاومة للصدأ بحفر ليزر بارز', 65.0, 5, NULL, 'keychain_metal.jpg', 'keychain_metal.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'ميدالية معدن مطلية بالاسم',
    description = 'ميدالية معدنية ثقيلة ومقاومة للصدأ بحفر ليزر بارز',
    price = 65.0,
    category_id = 5,
    subcategory_id = NULL,
    image_filename = 'keychain_metal.jpg',
    image_url = 'keychain_metal.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (35, 'ميدالية كابلز نصفين قلب', 'طقم ميداليتين متكاملتين للأزواج حفر ليزر مخصص', 80.0, 5, NULL, 'keychain_couples.jpg', 'keychain_couples.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'ميدالية كابلز نصفين قلب',
    description = 'طقم ميداليتين متكاملتين للأزواج حفر ليزر مخصص',
    price = 80.0,
    category_id = 5,
    subcategory_id = NULL,
    image_filename = 'keychain_couples.jpg',
    image_url = 'keychain_couples.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (36, 'شهادة تقدير كلاسيك مع إطار خشبي', 'شهادة تقدير مطبوعة ورق فاخر مع شيلد برواز خشب مذهب', 120.0, 6, NULL, 'certificate_frame.jpg', 'certificate_frame.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'شهادة تقدير كلاسيك مع إطار خشبي',
    description = 'شهادة تقدير مطبوعة ورق فاخر مع شيلد برواز خشب مذهب',
    price = 120.0,
    category_id = 6,
    subcategory_id = NULL,
    image_filename = 'certificate_frame.jpg',
    image_url = 'certificate_frame.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (37, 'شهادة تقدير أكريليك ميرور فاخرة', 'شهادة تكريم فاخرة على لوح أكريليك ذهبي/فضي مع طباعة UV وقاعدة', 250.0, 6, NULL, 'certificate_acrylic.jpg', 'certificate_acrylic.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'شهادة تقدير أكريليك ميرور فاخرة',
    description = 'شهادة تكريم فاخرة على لوح أكريليك ذهبي/فضي مع طباعة UV وقاعدة',
    price = 250.0,
    category_id = 6,
    subcategory_id = NULL,
    image_filename = 'certificate_acrylic.jpg',
    image_url = 'certificate_acrylic.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (38, 'فولدر شهادات مخمل فاخر بالاسم', 'فولدر قطيفة كبس ذهبي / سيلفر للشهايد والتكريمات الرسمية', 150.0, 6, NULL, 'certificate_folder.jpg', 'certificate_folder.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'فولدر شهادات مخمل فاخر بالاسم',
    description = 'فولدر قطيفة كبس ذهبي / سيلفر للشهايد والتكريمات الرسمية',
    price = 150.0,
    category_id = 6,
    subcategory_id = NULL,
    image_filename = 'certificate_folder.jpg',
    image_url = 'certificate_folder.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (39, 'تابلوه كانفاس إطار خشب داخلي 30x40', 'طباعة كانفاس أوروبي فاخر مشدود على خشب سويد متين', 180.0, 7, NULL, 'tableau_canvas_30x40.jpg', 'tableau_canvas_30x40.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'تابلوه كانفاس إطار خشب داخلي 30x40',
    description = 'طباعة كانفاس أوروبي فاخر مشدود على خشب سويد متين',
    price = 180.0,
    category_id = 7,
    subcategory_id = NULL,
    image_filename = 'tableau_canvas_30x40.jpg',
    image_url = 'tableau_canvas_30x40.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (40, 'تابلوه ثلاثي مودرن 3 قطع 30x40', 'طقم تابلوهات مودرن 3 قطع مفرغ حفر ليزر أو طباعة عالية الدقة', 450.0, 7, NULL, 'tableau_triptych.jpg', 'tableau_triptych.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'تابلوه ثلاثي مودرن 3 قطع 30x40',
    description = 'طقم تابلوهات مودرن 3 قطع مفرغ حفر ليزر أو طباعة عالية الدقة',
    price = 450.0,
    category_id = 7,
    subcategory_id = NULL,
    image_filename = 'tableau_triptych.jpg',
    image_url = 'tableau_triptych.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (41, 'تابلوه إسلامي أكريليك ميرور بارز', 'لوحة جدارية آيات قرآنية أكريليك مرايا على خشب أسود مضيء', 380.0, 7, NULL, 'tableau_islamic.jpg', 'tableau_islamic.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'تابلوه إسلامي أكريليك ميرور بارز',
    description = 'لوحة جدارية آيات قرآنية أكريليك مرايا على خشب أسود مضيء',
    price = 380.0,
    category_id = 7,
    subcategory_id = NULL,
    image_filename = 'tableau_islamic.jpg',
    image_url = 'tableau_islamic.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (42, 'محفظة جلد طبيعي حفر وش واحد', 'محفظة جلد طبيعي فاخرة مع حفر ليزر مخصص بالاسم أو الصورة على جهة واحدة', 160.0, 8, NULL, 'wallet_single_side.jpg', 'wallet_single_side.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'محفظة جلد طبيعي حفر وش واحد',
    description = 'محفظة جلد طبيعي فاخرة مع حفر ليزر مخصص بالاسم أو الصورة على جهة واحدة',
    price = 160.0,
    category_id = 8,
    subcategory_id = NULL,
    image_filename = 'wallet_single_side.jpg',
    image_url = 'wallet_single_side.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (43, 'محفظة جلد طبيعي حفر وشين', 'محفظة جلد طبيعي فخمة مع حفر ليزر مخصص على الجهتين بأعلى دقة', 200.0, 8, NULL, 'wallet_double_side.jpg', 'wallet_double_side.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'محفظة جلد طبيعي حفر وشين',
    description = 'محفظة جلد طبيعي فخمة مع حفر ليزر مخصص على الجهتين بأعلى دقة',
    price = 200.0,
    category_id = 8,
    subcategory_id = NULL,
    image_filename = 'wallet_double_side.jpg',
    image_url = 'wallet_double_side.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (44, 'طباعة التيشيرت الفاتح', 'طباعة حرارية عالية الجودة وثبات ألوان ممتازة على التيشيرتات الفاتحة', 50.0, 9, NULL, 'tshirt_light.jpg', 'tshirt_light.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'طباعة التيشيرت الفاتح',
    description = 'طباعة حرارية عالية الجودة وثبات ألوان ممتازة على التيشيرتات الفاتحة',
    price = 50.0,
    category_id = 9,
    subcategory_id = NULL,
    image_filename = 'tshirt_light.jpg',
    image_url = 'tshirt_light.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (45, 'طباعة التيشيرت الغامق', 'طباعة ديجيتال فاخرة وثقيلة للتيشيرتات الغامقة والسوداء مع ثبات ألوان ممتاز', 100.0, 9, NULL, 'tshirt_dark.jpg', 'tshirt_dark.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'طباعة التيشيرت الغامق',
    description = 'طباعة ديجيتال فاخرة وثقيلة للتيشيرتات الغامقة والسوداء مع ثبات ألوان ممتاز',
    price = 100.0,
    category_id = 9,
    subcategory_id = NULL,
    image_filename = 'tshirt_dark.jpg',
    image_url = 'tshirt_dark.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (46, 'درع كريستال هرمي مع علبة قطيفة', 'درع كريستال نقي كبس حراري وحفر ليزر 3D راقي', 320.0, 10, NULL, 'trophy_crystal.jpg', 'trophy_crystal.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'درع كريستال هرمي مع علبة قطيفة',
    description = 'درع كريستال نقي كبس حراري وحفر ليزر 3D راقي',
    price = 320.0,
    category_id = 10,
    subcategory_id = NULL,
    image_filename = 'trophy_crystal.jpg',
    image_url = 'trophy_crystal.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (47, 'درع خشب في أكريليك مذهب', 'درع تكريم خشبي فاخر مكسو بطبقة أكريليك ميرور ذهبي مع قاعدة', 260.0, 10, NULL, 'trophy_wood_acrylic.jpg', 'trophy_wood_acrylic.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'درع خشب في أكريليك مذهب',
    description = 'درع تكريم خشبي فاخر مكسو بطبقة أكريليك ميرور ذهبي مع قاعدة',
    price = 260.0,
    category_id = 10,
    subcategory_id = NULL,
    image_filename = 'trophy_wood_acrylic.jpg',
    image_url = 'trophy_wood_acrylic.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (48, 'شيلد نحاس على قاعدة خشبية', 'درع تكريم رسمي شيلد معدن مطلي ذهبي/فضي على خشب زان', 380.0, 10, NULL, 'trophy_metal_shield.jpg', 'trophy_metal_shield.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'شيلد نحاس على قاعدة خشبية',
    description = 'درع تكريم رسمي شيلد معدن مطلي ذهبي/فضي على خشب زان',
    price = 380.0,
    category_id = 10,
    subcategory_id = NULL,
    image_filename = 'trophy_metal_shield.jpg',
    image_url = 'trophy_metal_shield.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (49, 'قلم مضيء خط أزرق تاتش', 'قلم فاخر 3 في 1 (قلم جاف أزرق + إضاءة LED مخصصة + رأس تاتش للشاشات الذكية)', 70.0, 11, NULL, 'pen_light_touch.jpg', 'pen_light_touch.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'قلم مضيء خط أزرق تاتش',
    description = 'قلم فاخر 3 في 1 (قلم جاف أزرق + إضاءة LED مخصصة + رأس تاتش للشاشات الذكية)',
    price = 70.0,
    category_id = 11,
    subcategory_id = NULL,
    image_filename = 'pen_light_touch.jpg',
    image_url = 'pen_light_touch.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (50, 'طقم قلم معدني فاخر مع علبة هدايا', 'قلم معدني حفر ليزر بالاسم مع علبة مخملية شيك', 120.0, 11, NULL, 'pen_gift_set.jpg', 'pen_gift_set.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'طقم قلم معدني فاخر مع علبة هدايا',
    description = 'قلم معدني حفر ليزر بالاسم مع علبة مخملية شيك',
    price = 120.0,
    category_id = 11,
    subcategory_id = NULL,
    image_filename = 'pen_gift_set.jpg',
    image_url = 'pen_gift_set.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (51, 'ستاند مكتب خشب مع ساعة وقلم', 'ستاند مكتبي تنفيذي خشب زان حفر ليزر مع حامل كروت وساعة أنيقة', 290.0, 12, NULL, 'desk_stand_gold_wood.jpg', 'desk_stand_gold_wood.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'ستاند مكتب خشب مع ساعة وقلم',
    description = 'ستاند مكتبي تنفيذي خشب زان حفر ليزر مع حامل كروت وساعة أنيقة',
    price = 290.0,
    category_id = 12,
    subcategory_id = NULL,
    image_filename = 'desk_stand_gold_wood.jpg',
    image_url = 'desk_stand_gold_wood.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (52, 'ستاند اسم مكتبي أكريليك بارز', 'ستاند اسم أكريليك شفاف في أسود وذهبي بارز للمدراء والمحامين والأطباء', 240.0, 12, NULL, 'desk_stands.jpg', 'desk_stands.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'ستاند اسم مكتبي أكريليك بارز',
    description = 'ستاند اسم أكريليك شفاف في أسود وذهبي بارز للمدراء والمحامين والأطباء',
    price = 240.0,
    category_id = 12,
    subcategory_id = NULL,
    image_filename = 'desk_stands.jpg',
    image_url = 'desk_stands.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (53, 'علم ريشة كبير (Feather Flag)', 'علم ريشة خارجي مقاس كبير مع ستاند وتثبيت ممتاز للشركات والمعارض', 700.0, 13, NULL, 'flag_feather.jpg', 'flag_feather.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'علم ريشة كبير (Feather Flag)',
    description = 'علم ريشة خارجي مقاس كبير مع ستاند وتثبيت ممتاز للشركات والمعارض',
    price = 700.0,
    category_id = 13,
    subcategory_id = NULL,
    image_filename = 'flag_feather.jpg',
    image_url = 'flag_feather.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (54, 'علم مكتب استانلس فاخر', 'علم مكتب أنيق مع قاعدة وسارية ستانلس فاخرة للمكاتب والشركات', 250.0, 13, NULL, 'flag_desk.jpg', 'flag_desk.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'علم مكتب استانلس فاخر',
    description = 'علم مكتب أنيق مع قاعدة وسارية ستانلس فاخرة للمكاتب والشركات',
    price = 250.0,
    category_id = 13,
    subcategory_id = NULL,
    image_filename = 'flag_desk.jpg',
    image_url = 'flag_desk.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (55, 'ختم أوتوماتيك مستطيل (Trodat)', 'ختم حبر ذاتي مستطيل ماركة ترودات الأصلية ليزر عالي الدقة', 220.0, 14, NULL, 'stamp_auto.jpg', 'stamp_auto.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'ختم أوتوماتيك مستطيل (Trodat)',
    description = 'ختم حبر ذاتي مستطيل ماركة ترودات الأصلية ليزر عالي الدقة',
    price = 220.0,
    category_id = 14,
    subcategory_id = NULL,
    image_filename = 'stamp_auto.jpg',
    image_url = 'stamp_auto.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (56, 'ختم جيب بيضاوي متنقل', 'ختم محمول صغير الحجم يوضع بالجيب حبر داخلي للأطباء والمهندسين', 250.0, 14, NULL, 'stamp_pocket.jpg', 'stamp_pocket.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'ختم جيب بيضاوي متنقل',
    description = 'ختم محمول صغير الحجم يوضع بالجيب حبر داخلي للأطباء والمهندسين',
    price = 250.0,
    category_id = 14,
    subcategory_id = NULL,
    image_filename = 'stamp_pocket.jpg',
    image_url = 'stamp_pocket.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (57, 'ختم شمعي كلاسيك حفر نحاس', 'ختم شمع كلاسيكي بمقبض خشبي وحفر نحاس للمناسبات والفخامة', 280.0, 14, NULL, 'stamp_wax.jpg', 'stamp_wax.jpg', FALSE, NULL, NULL)
ON CONFLICT (id) DO UPDATE SET 
    name = 'ختم شمعي كلاسيك حفر نحاس',
    description = 'ختم شمع كلاسيكي بمقبض خشبي وحفر نحاس للمناسبات والفخامة',
    price = 280.0,
    category_id = 14,
    subcategory_id = NULL,
    image_filename = 'stamp_wax.jpg',
    image_url = 'stamp_wax.jpg',
    is_offer = FALSE,
    original_price = NULL,
    offer_discount = NULL;
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (58, 'عرض باقة العرسان الملكية', 'باقة تشمل روب العروسة + طارة الشبكة + طقم الشوكة والسكينة + 2 مج هدية', 699.0, 4, NULL, 'special_offer.jpg', 'special_offer.jpg', TRUE, 950.0, '26%')
ON CONFLICT (id) DO UPDATE SET 
    name = 'عرض باقة العرسان الملكية',
    description = 'باقة تشمل روب العروسة + طارة الشبكة + طقم الشوكة والسكينة + 2 مج هدية',
    price = 699.0,
    category_id = 4,
    subcategory_id = NULL,
    image_filename = 'special_offer.jpg',
    image_url = 'special_offer.jpg',
    is_offer = TRUE,
    original_price = 950.0,
    offer_discount = '26%';
INSERT INTO public.products (id, name, description, price, category_id, subcategory_id, image_filename, image_url, is_offer, original_price, offer_discount)
VALUES (59, 'عرض طقم المكتب المتكامل', 'ستاند اسم مكتبي + قلم تاتش مضيء + علم مكتب ستانلس فاخر', 450.0, 12, NULL, 'special_offer.jpg', 'special_offer.jpg', TRUE, 610.0, '25%')
ON CONFLICT (id) DO UPDATE SET 
    name = 'عرض طقم المكتب المتكامل',
    description = 'ستاند اسم مكتبي + قلم تاتش مضيء + علم مكتب ستانلس فاخر',
    price = 450.0,
    category_id = 12,
    subcategory_id = NULL,
    image_filename = 'special_offer.jpg',
    image_url = 'special_offer.jpg',
    is_offer = TRUE,
    original_price = 610.0,
    offer_discount = '25%';
SELECT setval('products_id_seq', COALESCE((SELECT MAX(id) FROM products), 1));


GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
