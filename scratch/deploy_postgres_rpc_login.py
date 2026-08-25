import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

rpc_sql = """
CREATE OR REPLACE FUNCTION public.normalize_phone_sql(p_phone TEXT)
RETURNS TEXT AS $$
DECLARE
    digits TEXT;
BEGIN
    IF p_phone IS NULL THEN
        RETURN '';
    END IF;
    digits := regexp_replace(p_phone, '\D', '', 'g');
    IF length(digits) > 10 THEN
        RETURN substring(digits from length(digits) - 9);
    END IF;
    RETURN digits;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


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
        RAISE EXCEPTION 'اسم المستخدم أو رقم الهاتف غير صحيح';
    END IF;

    v_clean_username := TRIM(p_username);
    v_clean_phone := TRIM(p_phone);

    -- 1. Find user by exact username (case-insensitive)
    SELECT * INTO v_user 
    FROM public.users 
    WHERE LOWER(username) = LOWER(v_clean_username) 
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'اسم المستخدم أو رقم الهاتف غير صحيح';
    END IF;

    -- 2. Check Lockout Status
    IF v_user.locked_until IS NOT NULL AND v_user.locked_until > NOW() THEN
        RAISE EXCEPTION 'تم قفل الحساب مؤقتاً، حاول بعد 15 دقيقة';
    END IF;

    -- 3. Normalize & Compare Phone Numbers
    v_stored_phone_norm := public.normalize_phone_sql(v_user.phone);
    v_input_phone_norm := public.normalize_phone_sql(v_clean_phone);

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

    -- Update user's phone if it was empty in database
    IF COALESCE(v_user.phone, '') = '' AND v_input_phone_norm <> '' THEN
        UPDATE public.users SET phone = v_clean_phone WHERE id = v_user.id;
    END IF;

    -- 4. Reset failed attempts & lockout on success
    UPDATE public.users 
    SET failed_login_attempts = 0, locked_until = NULL 
    WHERE id = v_user.id;

    -- 5. Find corresponding auth.users record ID
    v_email := LOWER(COALESCE(v_user.email, v_clean_username || '@gmail.com'));
    SELECT id INTO v_auth_user_id FROM auth.users WHERE LOWER(email) = v_email LIMIT 1;

    RETURN jsonb_build_object(
        'message', 'تم تسجيل الدخول بنجاح',
        'auth_user_id', v_auth_user_id,
        'user', jsonb_build_object(
            'id', v_user.id,
            'username', v_user.username,
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
        print("[SUCCESS] Created native Supabase RPC function 'passwordless_login'!")
    except Exception as e:
        print("[ERROR] Failed creating RPC function:", e)
