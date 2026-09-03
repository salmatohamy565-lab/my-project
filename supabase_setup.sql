-- =====================================================
-- Bola Designs - Complete Supabase Database Schema & Data
-- =====================================================


CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(120) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL,
    name VARCHAR(100),
    phone VARCHAR(30),
    photo_url VARCHAR(255),
    reset_otp VARCHAR(10),
    reset_otp_expires_at DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    description VARCHAR(500),
    price DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    image_filename VARCHAR(255),
    category_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    assigned_to INTEGER REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);


CREATE TABLE IF NOT EXISTS attendance (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    attendance_date VARCHAR(20) NOT NULL,
    check_in_time VARCHAR(20),
    check_out_time VARCHAR(20),
    status VARCHAR(20) DEFAULT 'present',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    customer_name VARCHAR(120),
    customer_phone VARCHAR(50),
    product_ids VARCHAR(255),
    items_summary TEXT,
    total_price DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    payment_method VARCHAR(50) DEFAULT 'instapay',
    payment_proof_filename VARCHAR(255),
    status VARCHAR(50) DEFAULT 'pending',
    rejection_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Allow all access to users'
    ) THEN
        CREATE POLICY "Allow all access to users" ON users FOR ALL TO public USING (true) WITH CHECK (true);
    END IF;
END
$$;

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'products' AND policyname = 'Allow all access to products'
    ) THEN
        CREATE POLICY "Allow all access to products" ON products FOR ALL TO public USING (true) WITH CHECK (true);
    END IF;
END
$$;

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'tasks' AND policyname = 'Allow all access to tasks'
    ) THEN
        CREATE POLICY "Allow all access to tasks" ON tasks FOR ALL TO public USING (true) WITH CHECK (true);
    END IF;
END
$$;

ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'attendance' AND policyname = 'Allow all access to attendance'
    ) THEN
        CREATE POLICY "Allow all access to attendance" ON attendance FOR ALL TO public USING (true) WITH CHECK (true);
    END IF;
END
$$;

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'orders' AND policyname = 'Allow all access to orders'
    ) THEN
        CREATE POLICY "Allow all access to orders" ON orders FOR ALL TO public USING (true) WITH CHECK (true);
    END IF;
END
$$;

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Allow all access to notifications'
    ) THEN
        CREATE POLICY "Allow all access to notifications" ON notifications FOR ALL TO public USING (true) WITH CHECK (true);
    END IF;
END
$$;


-- Data Migration: users
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (1, 'admin', 'admin@boladesigns.com', 'scrypt:32768:8:1$GXML4Ew7aQDnAj3C$78bd288af0d6336639d9cd0942708934b52be3e7da48ee47a46c9dddefa8c77d654f2ca186b800bff14b8a3e0ac93b7850e15ac2784a6d73e120fdc1fbf4d892', 'admin', 'admin')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (2, 'Bola', 'bola@boladesigns.com', 'scrypt:32768:8:1$1upHkwXYMESwrxH5$62b48b294d9f1b53beb468facc322e89ee16eafa9597caf24d2b3aadb1a4d6cce663f36d3a12fe9c9d402d270180eadd57696b7b10e16f9da4063fea857c6587', 'admin', 'Bola')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (3, 'customer_test_1d213e82', 'customer_test_1d213e82@boladesigns.com', 'scrypt:32768:8:1$1S6kmSjMtLxkgB6P$db590f5415d9c3c985219c925ffb6fc15c7da195b1126c88c6ef1b3890002b560d3dfeec9f406eb9f5925c43f0c865a21e62a7fd41608f638b3355dc41d479d8', 'customer', 'customer_test_1d213e82')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (4, 'customer_test_3e3c6d53', 'customer_test_3e3c6d53@boladesigns.com', 'scrypt:32768:8:1$CCIibkZbbwTBnTp8$d74ea434460210d618cc7b30bf884b53f164a5ee51204130458189abe59b68db51532defff3c5245cd489f65ec519045d9c8d8f3f0e40f10d871e3a717f7baef', 'customer', 'customer_test_3e3c6d53')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (5, 'customer_test_f6b13ce1', 'customer_test_f6b13ce1@boladesigns.com', 'scrypt:32768:8:1$NX12Yj5YUAOcAI5O$09f219c227aa4e502c8c8fa4d027608a5c114db17410aac5f89b6d702b967ba68e40c375a66d2de52a51c8cca072727fc930fff4b542c1e5c8851cafbf627d7a', 'customer', 'customer_test_f6b13ce1')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (6, 'testuser1', 'testuser1@boladesigns.com', 'scrypt:32768:8:1$slopUzjVesyDYfcW$b568fa84bd240e9ff719aba8e80cca5bb61b38fa9a82f89acb1e1be33bad2d994b9c3a1f055318908b30cab27ac269ebe831442738b70fe99917a9b5c68b308a', 'customer', 'testuser1')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (7, 'customer_test_9b388e55', 'customer_test_9b388e55@boladesigns.com', 'scrypt:32768:8:1$VGJ0KybIAQjjm18J$206071324d9126b9cb38ccc8df0dd98cadd2d9bbdfd7438321c25fe95ef7ea67033301e4d979432cb469094b97a1b170bb5141bba9c85d2616b482160423f857', 'customer', 'customer_test_9b388e55')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (8, 'salmawael442004', 'salmawael442004@boladesigns.com', 'scrypt:32768:8:1$NRzvlc1ZO0qMVhRX$7c3d824b4fb9098f6643b9e5e2b1459894ecf5f44d1b55046052c8af2627018aa7e0ab333bee4ae0f17faea8046ef18232670e267473d7408a883e980e653a91', 'customer', 'salmawael442004')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (9, 'malakmoatasem30', 'malakmoatasem30@boladesigns.com', 'scrypt:32768:8:1$g0vOkf77e9zFbqOG$173238424fb874f06891663e6af4903575f08eb33d1bb5e9f99b1c7b5bfce270c27ae0711b4f645ec321bc3fd2ca743e3781b1ddb0a6878d0f4405ef675a07ed', 'customer', 'malakmoatasem30')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (10, 'khlnjkbnjbk', 'khlnjkbnjbk@boladesigns.com', 'scrypt:32768:8:1$v675CWs3j8hfHsWn$0abdf5fa3ea4f7d748bb6b63ab21d4663def0fe17b32639b8e110e669fb8610c57e9fb495a4c2275341c12e3fc78f71dc886b5c0124ca7a36d6be3918da79c30', 'customer', 'khlnjkbnjbk')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (11, 'MALAK,OAHUJI', 'malak,oahuji@boladesigns.com', 'scrypt:32768:8:1$s9AVx3sLF2slx7Wo$8c303ecf13637cd7b38c2dd784cab6dcb84f8d11ac1315ee8e99babaaeb25c10ff13dc4ef2ac3279f2f814f8202b405bf22f7865c74dbaf034fc3a53e2d118ca', 'customer', 'MALAK,OAHUJI')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (12, 'MALAKMOATAS4EM', 'malakmoatas4em@boladesigns.com', 'scrypt:32768:8:1$IIR3j4Wp0KFkDKJJ$5976c73602fc5f2bc9bb33a3023f94063b2d200cee6c67b9bb37214b12f13fd08610e63be5281b08a0cce42fc52b46640610c99d87d1fc4f1fc418c389e57288', 'customer', 'MALAKMOATAS4EM')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (13, 'malakddd', 'malakddd@boladesigns.com', 'scrypt:32768:8:1$EefO76EulBF1hXzG$1f858327b7bfb80681a81b253761a1b5808d801e4913d02f349a60aee1ac0acd5bf7e57acf350c7697d397961161a209cb753f5e0c6e94fa03ed046c7fda6fbc', 'customer', 'malakddd')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (14, 'malak44', 'malak44@boladesigns.com', 'scrypt:32768:8:1$DNcWPOfToMX3KJcj$12dc43c3394b6157661c9f48ee8cedeb500d66515f51d6a210d98ac37ba70f1261bd5051a8c50815718ad992084e97f010f5191a1e48ae4c74b66bd9b1be13d5', 'customer', 'malak44')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (15, 'malakmoatasem44', 'malakmoatasem44@boladesigns.com', 'scrypt:32768:8:1$Owwk8QhSFeYfHS1Z$f9c86965f2fc36cbf2e561279f646635fe82997963dae0732aad1e130a60f416c517d4f0f14ff43633ccef1dafa72f481a7c3a7e593c045999128501b2e14002', 'customer', 'malakmoatasem44')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (16, 'malakmoatasem00', 'malakmoatasem00@boladesigns.com', 'scrypt:32768:8:1$uLdOILYTLrvx8Rj7$8afb88e27b9d1f727bc983dfd87da4fc8c2b1528233221611085acd89cc72d8103b4fc231450bc83b6777e6b6ccfd5d9c1ef91c214d87ba0f869c3212c2a727b', 'customer', 'malakmoatasem00')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (17, 'malak4444', 'malak4444@boladesigns.com', 'scrypt:32768:8:1$qCAKUTpxibJhhgYj$29ab4427ef4ab1be2519fbfb9f40393b59193980518dd298c02e27166e9b8fb29e14bd2e4a6a56eee664e4b400d71790f12e897536eeb51dd0fe5664aa5560d9', 'customer', 'malak4444')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (18, 'malakmoatasem999', 'malakmoatasem999@boladesigns.com', 'scrypt:32768:8:1$7ifH2qLwafdyBO3Y$5083007beeba1fbdca6181af2b3cb924d58cad3a6659b3afbda8d35c9a16db051718e36e5f90f2b2beb571520e987b47351aa183eb7626db3fa2cd2259a332fb', 'customer', 'malakmoatasem999')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (19, 'malkamoatasejm00', 'malkamoatasejm00@boladesigns.com', 'scrypt:32768:8:1$vrLOZg2gHRNtMgQ1$8e80baa85c606b44f42f0bc434ed1996d470bdd7d43eb7023c71b95d4ba6670b4ac4f5232f18f918de6e473d30a16a32f64497f7c7b8cce7d1993780d243a62e', 'customer', 'malkamoatasejm00')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (20, 'malakmoa44', 'malakmoa44@boladesigns.com', 'scrypt:32768:8:1$2Ai5B55ePOEOnUhx$a174770261ad7d42c2ed82c0de944fa44e9c9760b4ec42cf4b577fd78198b51c1459acf0d2b9d0bdabb1581a9cf21df08b8daab6bb6e8e8ec90f29d45c0c6806', 'customer', 'malakmoa44')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (21, 'malakmoatasem0088', 'malakmoatasem0088@boladesigns.com', 'scrypt:32768:8:1$58FZoeP3JJdm4QMm$d89ed7663b495774b87b7a7b725e72781b75a35fa3b79424e3dfa3e2c99699e3c2e502324bc6d84755300352a47c8c9fb589c2ff88e8ff30559a5c9d52c093f0', 'customer', 'malakmoatasem0088')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (22, 'malakmoatasem9999999', 'malakmoatasem9999999@boladesigns.com', 'scrypt:32768:8:1$IxquK45eJKegVdFw$ba3373ffff0c8fa2a034c94e10d419acdec09aa0408a18e6eefad3240a3dd070fe18653bf5054d93a61ada3249ed079e5f17ac3560fce91f0a4ad88e8c4f5f00', 'customer', 'malakmoatasem9999999')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (23, 'malakmoatasemk', 'malakmoatasemk@boladesigns.com', 'scrypt:32768:8:1$s5xXf8Lqd4H3P4DF$efc194b53702de8cc18ffab55f4355dbddbf81e7dc83bb0a0595c02dbd1fe8b9dee1a40a6b14c59fc2cfcff99300f7eea2d7ba4f3a878ab8bb5683daa7e7fd40', 'customer', 'malakmoatasemk')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (24, 'malajjdbdh', 'malajjdbdh@boladesigns.com', 'scrypt:32768:8:1$Z407ZtHCNhQG0zlj$748a518e8dd91f84f92765f33a4c0f77e6cbbeaf883174781be568e6b78c47f094f656140739358252b7b2aa3dd88e9613caf7fff10d851ce93384ad27143f37', 'customer', 'malajjdbdh')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (25, 'malakmoatasem0008780', 'malakmoatasem0008780@boladesigns.com', 'scrypt:32768:8:1$bdK7nSDr7zUR9bhL$86a5f08d5597eb0d8771913436e83b6b670c33d6d4520f1ac6f3aad998b1eb0c9fbe2fe5c4436fe20e0e9a801e06830d013b21dd2f6620b7b05070de008ac0d3', 'customer', 'malakmoatasem0008780')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (26, 'a;al;''\l.', 'a;al;''\l.@boladesigns.com', 'scrypt:32768:8:1$AAM76Lqc4cv5mSIz$6959117aab3348fd9967b93447a29c4c84177202026e4c1a30d1678a4447d659108656c6578df6f45ee56e815f6a3187c4ab4698b38afd0a1a85d1d6cbef021a', 'customer', 'a;al;''\l.')
ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, username, email, password_hash, role, name)
VALUES (27, 'safdtgdftafty', 'safdtgdftafty@boladesigns.com', 'scrypt:32768:8:1$jIY8T4imiZFqn4tO$a48363e3b27d876678bfcdada7da719a7665866e137d0249721f97725e5546b38861527f9065a76e0336473ae954debfc8dc600533fac85818d8a7b802e9d40e', 'customer', 'safdtgdftafty')
ON CONFLICT (id) DO NOTHING;

-- Update sequence for users
SELECT setval('users_id_seq', COALESCE((SELECT MAX(id) FROM users), 1));


-- Data Migration: products
INSERT INTO products (id, name, description, price, image_filename, category_id)
VALUES (1, 'تصميم هوية تجارية', 'باقة كاملة لتصميم الشعار والهوية البصرية.', 1200.0, NULL, NULL)
ON CONFLICT (id) DO NOTHING;
INSERT INTO products (id, name, description, price, image_filename, category_id)
VALUES (2, 'لوحة إعلانية رقمية', 'تصميم إعلان رقمي جاهز للنشر على السوشيال ميديا.', 450.0, NULL, NULL)
ON CONFLICT (id) DO NOTHING;
INSERT INTO products (id, name, description, price, image_filename, category_id)
VALUES (3, 'عرض تقديمي احترافي', 'تصميم عرض تقديمي مميز للشركات والمشاريع.', 800.0, NULL, NULL)
ON CONFLICT (id) DO NOTHING;

-- Update sequence for products
SELECT setval('products_id_seq', COALESCE((SELECT MAX(id) FROM products), 1));


-- Data Migration: attendance
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (1, 2, '2026-07-23', '16:02', '16:02', 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (2, 3, '2026-07-23', '19:07', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (3, 1, '2026-07-23', '19:07', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (4, 4, '2026-07-23', '19:08', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (5, 5, '2026-07-23', '19:17', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (6, 7, '2026-07-23', '20:13', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (7, 8, '2026-07-25', '13:39', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (8, 9, '2026-07-25', '15:09', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (9, 10, '2026-07-25', '15:34', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (10, 11, '2026-07-25', '15:56', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (11, 12, '2026-07-25', '16:29', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (12, 13, '2026-07-25', '17:31', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (13, 14, '2026-07-25', '18:00', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (14, 15, '2026-07-25', '18:06', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (15, 16, '2026-07-25', '18:19', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (16, 17, '2026-07-25', '18:39', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (17, 18, '2026-07-25', '18:45', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (18, 19, '2026-07-25', '19:12', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (19, 20, '2026-07-25', '19:18', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (20, 21, '2026-07-25', '19:47', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (21, 22, '2026-07-25', '20:12', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (22, 23, '2026-07-25', '20:53', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (23, 24, '2026-07-25', '21:20', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (24, 25, '2026-07-26', '14:08', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (25, 26, '2026-07-26', '14:13', NULL, 'present')
ON CONFLICT (id) DO NOTHING;
INSERT INTO attendance (id, user_id, attendance_date, check_in_time, check_out_time, status)
VALUES (26, 27, '2026-07-26', '15:08', NULL, 'present')
ON CONFLICT (id) DO NOTHING;

-- Update sequence for attendance
SELECT setval('attendance_id_seq', COALESCE((SELECT MAX(id) FROM attendance), 1));
