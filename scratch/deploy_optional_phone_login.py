import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

rpc_sql = """
CREATE OR REPLACE FUNCTION public.passwordless_login(p_username TEXT, p_phone TEXT DEFAULT '')
RETURNS JSONB AS $$
DECLARE
    v_clean_username TEXT;
    v_clean_phone TEXT;
    v_input_phone_norm TEXT;
    v_stored_phone_norm TEXT;
    v_email TEXT;
    v_matched_user RECORD;
    v_candidate RECORD;
    v_current_failed INT;
    v_lock_until TIMESTAMPTZ;
BEGIN
    IF p_username IS NULL OR TRIM(p_username) = '' THEN
        RAISE EXCEPTION 'يرجى إدخال اسم المستخدم';
    END IF;

    v_clean_username := TRIM(p_username);
    v_clean_phone := TRIM(COALESCE(p_phone, ''));
    v_input_phone_norm := public.normalize_phone_sql(v_clean_phone);
    v_matched_user := NULL;

    -- 1. Search across username, name, or email
    FOR v_candidate IN 
        SELECT * FROM public.users 
        WHERE LOWER(username) = LOWER(v_clean_username) 
           OR LOWER(name) = LOWER(v_clean_username)
           OR LOWER(email) = LOWER(v_clean_username)
    LOOP
        -- If phone input is empty OR candidate phone is empty OR phone matches
        v_stored_phone_norm := public.normalize_phone_sql(v_candidate.phone);
        
        IF v_input_phone_norm = '' OR
           v_stored_phone_norm = '' OR
           v_stored_phone_norm = v_input_phone_norm THEN
            v_matched_user := v_candidate;
            EXIT;
        END IF;
    END LOOP;

    -- 2. If candidates existed but phone didn't match
    IF v_matched_user IS NULL THEN
        SELECT * INTO v_candidate FROM public.users 
        WHERE LOWER(username) = LOWER(v_clean_username) 
           OR LOWER(name) = LOWER(v_clean_username)
           OR LOWER(email) = LOWER(v_clean_username)
        LIMIT 1;

        IF FOUND THEN
            -- Check Lockout
            IF v_candidate.locked_until IS NOT NULL AND v_candidate.locked_until > NOW() THEN
                RAISE EXCEPTION 'تم قفل الحساب مؤقتاً، حاول بعد 15 دقيقة';
            END IF;

            v_current_failed := COALESCE(v_candidate.failed_login_attempts, 0) + 1;
            IF v_current_failed >= 5 THEN
                v_lock_until := NOW() + INTERVAL '15 minutes';
                UPDATE public.users SET failed_login_attempts = v_current_failed, locked_until = v_lock_until WHERE id = v_candidate.id;
                RAISE EXCEPTION 'تم قفل الحساب مؤقتاً، حاول بعد 15 دقيقة';
            ELSE
                UPDATE public.users SET failed_login_attempts = v_current_failed WHERE id = v_candidate.id;
                RAISE EXCEPTION 'اسم المستخدم أو رقم الهاتف غير صحيح';
            END IF;
        ELSE
            -- 3. New User: Auto-register on the fly
            v_email := LOWER(v_clean_username) || '@gmail.com';
            INSERT INTO public.users (username, name, email, phone, role, password_hash, created_at)
            VALUES (v_clean_username, v_clean_username, v_email, v_clean_phone, 'customer', 'passwordless', NOW())
            RETURNING * INTO v_matched_user;
        END IF;
    END IF;

    -- 4. Check Lockout on matched user
    IF v_matched_user.locked_until IS NOT NULL AND v_matched_user.locked_until > NOW() THEN
        RAISE EXCEPTION 'تم قفل الحساب مؤقتاً، حاول بعد 15 دقيقة';
    END IF;

    -- Update phone if empty in DB and user provided one
    IF COALESCE(v_matched_user.phone, '') = '' AND v_input_phone_norm <> '' THEN
        UPDATE public.users SET phone = v_clean_phone WHERE id = v_matched_user.id;
    END IF;

    -- Reset failed attempts & lockout on success
    UPDATE public.users SET failed_login_attempts = 0, locked_until = NULL WHERE id = v_matched_user.id;

    -- 5. Get/Create corresponding auth.users record ID
    v_email := LOWER(COALESCE(v_matched_user.email, v_clean_username || '@gmail.com'));
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
            'id', v_matched_user.id,
            'username', COALESCE(v_matched_user.username, v_clean_username),
            'name', COALESCE(v_matched_user.name, v_clean_username),
            'email', v_email,
            'phone', COALESCE(v_matched_user.phone, v_clean_phone),
            'role', COALESCE(v_matched_user.role, 'customer'),
            'is_admin', (v_matched_user.role = 'admin' OR v_matched_user.role = 'owner'),
            'is_employee', (v_matched_user.role = 'employee')
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
"""

with engine.connect() as conn:
    try:
        conn.execute(text(rpc_sql))
        conn.commit()
        print("[SUCCESS] Deployed optional phone passwordless_login Postgres RPC!")
    except Exception as e:
        print("[ERROR] Failed deploying RPC:", e)
