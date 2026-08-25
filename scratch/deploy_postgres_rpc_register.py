import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

rpc_sql = """
CREATE OR REPLACE FUNCTION public.passwordless_register(p_username TEXT, p_phone TEXT)
RETURNS JSONB AS $$
DECLARE
    v_clean_username TEXT;
    v_clean_phone TEXT;
    v_email TEXT;
    v_existing_id INT;
    v_new_user RECORD;
    v_auth_user_id UUID;
BEGIN
    IF p_username IS NULL OR p_phone IS NULL OR TRIM(p_username) = '' OR TRIM(p_phone) = '' THEN
        RAISE EXCEPTION 'يرجى إدخال اسم المستخدم ورقم الهاتف';
    END IF;

    v_clean_username := TRIM(p_username);
    v_clean_phone := TRIM(p_phone);
    v_email := LOWER(v_clean_username) || '@gmail.com';

    -- 1. Check if username already exists
    SELECT id INTO v_existing_id 
    FROM public.users 
    WHERE LOWER(username) = LOWER(v_clean_username) 
    LIMIT 1;

    IF v_existing_id IS NOT NULL THEN
        RAISE EXCEPTION 'اسم المستخدم مسجل بالفعل، يرجى اختيار اسم آخر أو تسجيل الدخول';
    END IF;

    -- 2. Insert into public.users
    INSERT INTO public.users (username, name, email, phone, role, password_hash, created_at)
    VALUES (v_clean_username, v_clean_username, v_email, v_clean_phone, 'customer', 'passwordless', NOW())
    RETURNING * INTO v_new_user;

    -- 3. Ensure corresponding auth.users record exists
    SELECT id INTO v_auth_user_id FROM auth.users WHERE LOWER(email) = v_email LIMIT 1;
    IF v_auth_user_id IS NULL THEN
        v_auth_user_id := gen_random_uuid();
        INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role)
        VALUES (v_auth_user_id, '00000000-0000-0000-0000-000000000000', v_email, 'passwordless', NOW(), '{"provider":"email","providers":["email"]}', jsonb_build_object('username', v_clean_username), NOW(), NOW(), 'authenticated')
        ON CONFLICT (email) DO NOTHING;
    END IF;

    RETURN jsonb_build_object(
        'message', 'تم إنشاء الحساب بنجاح',
        'auth_user_id', v_auth_user_id,
        'user', jsonb_build_object(
            'id', v_new_user.id,
            'username', v_new_user.username,
            'name', v_new_user.name,
            'email', v_email,
            'phone', v_new_user.phone,
            'role', 'customer',
            'is_admin', false,
            'is_employee', false
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
"""

with engine.connect() as conn:
    try:
        conn.execute(text(rpc_sql))
        conn.commit()
        print("[SUCCESS] Created native Supabase RPC function 'passwordless_register'!")
    except Exception as e:
        print("[ERROR] Failed creating passwordless_register RPC:", e)
