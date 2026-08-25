import os
import sys
import json
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

email = "salmatohamy565@gmail.com"

with engine.connect() as conn:
    print(f"=== [1] Querying auth.users for {email} ===")
    res_users = conn.execute(text("SELECT id, instance_id, email, encrypted_password, email_confirmed_at, raw_user_meta_data, raw_app_meta_data, created_at, updated_at, banned_until, deleted_at FROM auth.users WHERE LOWER(email) = :email;"), {"email": email}).fetchall()
    print(f"Found {len(res_users)} rows in auth.users:")
    for u in res_users:
        d = dict(u._mapping)
        print(f"  User ID: {d['id']}")
        print(f"  instance_id: {d['instance_id']}")
        print(f"  encrypted_password length: {len(d['encrypted_password'] or '')}")
        print(f"  raw_user_meta_data: {d['raw_user_meta_data']}")
        print(f"  raw_app_meta_data: {d['raw_app_meta_data']}")
        print(f"  created_at: {d['created_at']}")
        print(f"  banned_until: {d['banned_until']}")
        print(f"  deleted_at: {d['deleted_at']}")

    print(f"\n=== [2] Querying auth.identities for {email} ===")
    res_identities = conn.execute(text("SELECT id, user_id, identity_data, provider, provider_id, created_at, updated_at FROM auth.identities WHERE LOWER(email) = :email OR user_id IN (SELECT id FROM auth.users WHERE LOWER(email) = :email);"), {"email": email}).fetchall()
    print(f"Found {len(res_identities)} rows in auth.identities:")
    for i in res_identities:
        d = dict(i._mapping)
        print(f"  Identity ID: {d['id']}")
        print(f"  user_id: {d['user_id']}")
        print(f"  provider: {d['provider']}")
        print(f"  provider_id: {d['provider_id']}")
        print(f"  identity_data: {d['identity_data']}")

    print("\n=== [3] Checking All Triggers on auth.users ===")
    res_triggers = conn.execute(text("""
        SELECT trigger_name, event_manipulation, event_object_table, action_statement, action_timing 
        FROM information_schema.triggers 
        WHERE event_object_table = 'users' OR event_object_schema = 'auth';
    """)).fetchall()
    print(f"Found {len(res_triggers)} triggers on auth/users:")
    for t in res_triggers:
        print(dict(t._mapping))

    print("\n=== [4] Checking All Functions on auth / public schemas ===")
    res_funcs = conn.execute(text("""
        SELECT routine_name, routine_type 
        FROM information_schema.routines 
        WHERE routine_schema IN ('auth', 'public') AND routine_name LIKE '%user%';
    """)).fetchall()
    for f in res_funcs:
        print(dict(f._mapping))
