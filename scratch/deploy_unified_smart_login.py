import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

rpc_sql = """
CREATE OR REPLACE FUNCTION public.passwordless_login(p_username TEXT, p_phone TEXT)
RETURNS JSONB AS $$
DECLARE
    v_user RECORD;
    v_stored_phone_norm TEXT;
    v_input_phone_norm TEXT;
    v_is_match BOOLEAN;
    v_current_failed INT;
    v_lock_until TIMESTAMPTZ;
    v_clean_username TEXT;
    v_clean_phone TEXT;
    v_auth_user_id UUID;
    v_email TEXT;
BEGIN
    IF p_username IS NULL OR p_phone IS NULL OR TRIM(p_username) = '' OR TRIM(p_phone) = '' THEN
        RAISE EXCEPTION 'يرجى إدخال اسم المستخدم ورقم الهاتف';
    END IF;

    v_clean_username := TRIM(p_username);
    v_clean_phone := TRIM(p_phone);
    v_input_phone_norm := public.normalize_phone_sql(v_clean_phone);
    v_email := LOWER(v_clean_username) || '@gmail.com';

    -- 1. Search for user by username
    SELECT * INTO v_user 
    FROM public.users 
    WHERE LOWER(username) = LOWER(v_clean_username) 
    LIMIT 1;

    -- 2. IF NOT FOUND: Auto-create new user on the fly (Smart Register)
    IF NOT FOUND THEN
        INSERT INTO public.users (username, name, email, phone, role, password_hash, created_at)
        VALUES (v_clean_username, v_clean_username, v_email, v_clean_phone, 'customer', 'passwordless', NOW())
        RETURNING * INTO v_user;
    ELSE
        -- Check Lockout Status for existing user
        IF v_user.locked_until IS NOT NULL AND v_user.locked_until > NOW() THEN
            RAISE EXCEPTION 'تم قفل الحساب مؤقتاً، حاول بعد 15 دقيقة';
        END IF;

        -- Normalize & Compare Phone Numbers
        v_stored_phone_norm := public.normalize_phone_sql(v_user.phone);

        v_is_match := (v_stored_phone_norm <> '' AND v_stored_phone_norm = v_input_phone_norm) OR
                      (v_stored_phone_norm = '' AND v_input_phone_norm <> '');

        IF NOT v_is_match THEN
            v_current_failed := COALESCE(v_user.failed_login_attempts, 0) + 1;
            
            IF v_current_failed >= 5 THEN
                v_lock_until := NOW() + INTERVAL '15 minutes';
                UPDATE public.users 
                SET failed_login_attempts = v_current_failed, locked_until = v_lock_until 
                WHERE id = v_user.id;
                
                RAISE EXCEPTION 'تم قفل الحساب مؤقتاً، حاول بعد 15 دقيقة';
            ELSE
                UPDATE public.users 
                SET failed_login_attempts = v_current_failed 
                WHERE id = v_user.id;
                
                RAISE EXCEPTION 'اسم المستخدم أو رقم الهاتف غير صحيح';
            END IF;
        END IF;

        -- Update user phone if empty
        IF COALESCE(v_user.phone, '') = '' AND v_input_phone_norm <> '' THEN
            UPDATE public.users SET phone = v_clean_phone WHERE id = v_user.id;
        END IF;

        -- Reset failed attempts & lockout on success
        UPDATE public.users 
        SET failed_login_attempts = 0, locked_until = NULL 
        WHERE id = v_user.id;
    END IF;

    -- 3. Ensure corresponding auth.users record ID
    SELECT id INTO v_auth_user_id FROM auth.users WHERE LOWER(email) = v_email LIMIT 1;
    IF v_auth_user_id IS NULL THEN
        v_auth_user_id := gen_random_uuid();
        INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role)
        VALUES (v_auth_user_id, '00000000-0000-0000-0000-000000000000', v_email, 'passwordless', NOW(), '{"provider":"email","providers":["email"]}', jsonb_build_object('username', v_clean_username), NOW(), NOW(), 'authenticated')
        ON CONFLICT (email) DO NOTHING;
    END IF;

    RETURN jsonb_build_object(
        'message', 'تم تسجيل الدخول بنجاح',
        'auth_user_id', v_auth_user_id,
        'user', jsonb_build_object(
            'id', v_user.id,
            'username', v_user.username,
            'name', COALESCE(v_user.name, v_user.username),
            'email', v_email,
            'phone', COALESCE(v_user.phone, v_clean_phone),
            'role', COALESCE(v_user.role, 'customer'),
            'is_admin', (v_user.role = 'admin' OR v_user.role = 'owner'),
            'is_employee', (v_user.role = 'employee')
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
"""

with engine.connect() as conn:
    try:
        conn.execute(text(rpc_sql))
        conn.commit()
        print("[SUCCESS] Deployed unified smart passwordless_login Postgres RPC!")
    except Exception as e:
        print("[ERROR] Failed deploying smart passwordless_login RPC:", e)
