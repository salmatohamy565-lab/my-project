import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
import requests
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

supabase_url = "https://kxeqayzxfvoedqvilcmp.supabase.co"
anon_key = "sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E"
rpc_url = f"{supabase_url}/rest/v1/rpc/passwordless_login"
headers = {
    "apikey": anon_key,
    "Authorization": f"Bearer {anon_key}",
    "Content-Type": "application/json"
}

with engine.connect() as conn:
    print("--- Inspecting public.users records for Admins & Employees ---")
    res = conn.execute(text("SELECT id, username, name, email, phone, role, failed_login_attempts, locked_until FROM public.users WHERE role IN ('admin', 'employee') OR LOWER(username) LIKE 'admin%' OR LOWER(username) LIKE 'emp%';")).fetchall()
    for row in res:
        print(f"ID: {row[0]}, Username: '{row[1]}', Name: '{row[2]}', Email: '{row[3]}', Phone: '{row[4]}', Role: '{row[5]}', FailedAttempts: {row[6]}, LockedUntil: {row[7]}")

test_usernames = ["admin_bola_01", "admin_eman_02", "emp_malak_101", "emp_salma_102", "emp_dieved_103", "emp_abdelkreem_104", "Bola", "Malak", "Salma", "admin", "employee"]

print("\n--- Testing RPC calls with empty phone ---")
for un in test_usernames:
    try:
        r = requests.post(rpc_url, headers=headers, json={"p_username": un, "p_phone": ""}, timeout=5)
        print(f"Username '{un}' -> Status: {r.status_code}, Response: {r.text}")
    except Exception as e:
        print(f"Username '{un}' -> Error: {e}")
