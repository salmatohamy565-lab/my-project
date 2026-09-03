-- ==========================================================
-- RESTORE ORIGINAL USER CATEGORY & PRODUCT IMAGES
-- ==========================================================

-- 1. FIX CATEGORIES COVER IMAGES
UPDATE public.categories SET image_url = 'wallet_engraved_group.jpg' WHERE name LIKE '%محافظ%' OR name LIKE '%محفظ%';
UPDATE public.categories SET image_url = 'wedding_invitation_ribbon.jpg' WHERE name LIKE '%افراح%' OR name LIKE '%مستلزمات%';
UPDATE public.categories SET image_url = 'keychain_soft_photo.jpg' WHERE name LIKE '%ميدالي%';
UPDATE public.categories SET image_url = 'cert_navy_gold.jpg' WHERE name LIKE '%شهادات%';
UPDATE public.categories SET image_url = 'mug_white_real.jpg' WHERE name LIKE '%مج%';
UPDATE public.categories SET image_url = 'tableaux.jpg' WHERE name LIKE '%تابلوه%';
UPDATE public.categories SET image_url = 'trophies.jpg' WHERE name LIKE '%دروع%' OR name LIKE '%درع%';
UPDATE public.categories SET image_url = 'tshirts.jpg' WHERE name LIKE '%تيشرت%';
UPDATE public.categories SET image_url = 'flags.jpg' WHERE name LIKE '%اعلام%' OR name LIKE '%علم%';
UPDATE public.categories SET image_url = 'pens.jpg' WHERE name LIKE '%اقلام%' OR name LIKE '%قلم%';
UPDATE public.categories SET image_url = 'stamp_trodat_set.jpg' WHERE name LIKE '%اختام%' OR name LIKE '%ختم%';
UPDATE public.categories SET image_url = 'desk_stands.jpg' WHERE name LIKE '%ستاند%' OR name LIKE '%مكتب%';
UPDATE public.categories SET image_url = 'frames.jpg' WHERE name LIKE '%فوتوبلوك%' OR name LIKE '%براويز%';

-- 2. FIX WALLET PRODUCTS
UPDATE public.products SET image_filename = 'wallet_engraved_single.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/wallet_engraved_single.jpg' WHERE name LIKE '%وش واحد%';
UPDATE public.products SET image_filename = 'wallet_engraved_group.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/wallet_engraved_group.jpg' WHERE name LIKE '%وشين%';

-- 3. FIX WEDDING PRODUCTS
UPDATE public.products SET image_filename = 'wedding_contract_frame.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/wedding_contract_frame.jpg' WHERE name LIKE '%عقد قران%';
UPDATE public.products SET image_filename = 'wedding_invitation_ribbon.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/wedding_invitation_ribbon.jpg' WHERE name LIKE '%شرائط الستان%';
UPDATE public.products SET image_filename = 'wedding_pearl_lace_card.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/wedding_pearl_lace_card.jpg' WHERE name LIKE '%لؤلؤ وتول%';
UPDATE public.products SET image_filename = 'wedding_chocolate_cards.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/wedding_chocolate_cards.jpg' WHERE name LIKE '%توزيعات شوكولاتة%';
UPDATE public.products SET image_filename = 'wedding_save_the_date.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/wedding_save_the_date.jpg' WHERE name LIKE '%Save The Date%' OR name LIKE '%تقويم%';

-- 4. FIX PENS PRODUCTS
UPDATE public.products SET image_filename = 'pen_touch_laser_engraved.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/pen_touch_laser_engraved.jpg' WHERE name LIKE '%مضيء%' OR name LIKE '%تاتش%';
UPDATE public.products SET image_filename = 'pen_gold_luxury_box.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/pen_gold_luxury_box.jpg' WHERE name LIKE '%طقم قلم%' OR name LIKE '%معدني%';

-- 5. FIX MUGS PRODUCTS
UPDATE public.products SET image_filename = 'mug_lens_real.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/mug_lens_real.jpg' WHERE name LIKE '%عدسة%';
UPDATE public.products SET image_filename = 'mug_white_real.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/mug_white_real.jpg' WHERE name LIKE '%أبيض%' OR name LIKE '%سحري%';
UPDATE public.products SET image_filename = 'mug_digital_real.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/mug_digital_real.jpg' WHERE name LIKE '%ديجيتال%' OR name LIKE '%أزاز%';

-- 6. FIX TROPHIES PRODUCTS
UPDATE public.products SET image_filename = 'trophy_grad_cap_luxury.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/trophy_grad_cap_luxury.jpg' WHERE name LIKE '%قبعة التخرج%' OR name LIKE '%كريستال%';
UPDATE public.products SET image_filename = 'trophy_wood_grad_photo.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/trophy_wood_grad_photo.jpg' WHERE name LIKE '%خشبي%' OR name LIKE '%إطار صورة%';
UPDATE public.products SET image_filename = 'trophy_acrylic_quran_certificate.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/trophy_acrylic_quran_certificate.jpg' WHERE name LIKE '%القرآن%';
UPDATE public.products SET image_filename = 'trophy_acrylic_little_graduate.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/trophy_acrylic_little_graduate.jpg' WHERE name LIKE '%الصغير%';

-- 7. FIX FLAGS PRODUCTS
UPDATE public.products SET image_filename = 'flag_feather_blue.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/flag_feather_blue.jpg' WHERE name LIKE '%ريشة%' OR name LIKE '%كبير%';
UPDATE public.products SET image_filename = 'flag_desk_luxury.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/flag_desk_luxury.jpg' WHERE name LIKE '%علم مكتب%';

-- 8. FIX T-SHIRTS PRODUCTS
UPDATE public.products SET image_filename = 'tshirt_white_uniform_cap.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/tshirt_white_uniform_cap.jpg' WHERE name LIKE '%فاتح%';
UPDATE public.products SET image_filename = 'tshirt_black_gold_arabic.jpg', image_url = 'https://qqsjlkrzeleothumkknu.supabase.co/storage/v1/object/public/product_images/tshirt_black_gold_arabic.jpg' WHERE name LIKE '%غامق%' OR name LIKE '%اسود%';

NOTIFY pgrst, 'reload schema';
