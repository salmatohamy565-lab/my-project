import requests
import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

supabase_url = "https://kxeqayzxfvoedqvilcmp.supabase.co"
anon_key = "sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E"

url = f"{supabase_url}/rest/v1/rpc/passwordless_login"
headers = {
    "apikey": anon_key,
    "Authorization": f"Bearer {anon_key}",
    "Content-Type": "application/json"
}

test_cases = [
    {"name": "admin (with random phone)", "payload": {"p_username": "admin", "p_phone": "01234567890"}},
    {"name": "admin_bola_01 (with random phone)", "payload": {"p_username": "admin_bola_01", "p_phone": "01234567890"}},
    {"name": "admin_eman_02 (with empty phone)", "payload": {"p_username": "admin_eman_02", "p_phone": ""}},
    {"name": "employee (with random phone)", "payload": {"p_username": "employee", "p_phone": "01999999999"}},
    {"name": "emp_malak_101 (with empty phone)", "payload": {"p_username": "emp_malak_101", "p_phone": ""}},
    {"name": "emp_salma_102 (with random phone)", "payload": {"p_username": "emp_salma_102", "p_phone": "01271122860"}},
    {"name": "emp_dieved_103 (with random phone)", "payload": {"p_username": "emp_dieved_103", "p_phone": "01555555555"}},
    {"name": "emp_abdelkreem_104 (with empty phone)", "payload": {"p_username": "emp_abdelkreem_104", "p_phone": ""}},
]

for tc in test_cases:
    print(f"\n--- Testing: {tc['name']} ---")
    try:
        r = requests.post(url, headers=headers, json=tc['payload'], timeout=5)
        res = r.json()
        user = res.get('user', {})
        print(f"Status: {r.status_code} | Role: {user.get('role')} | is_admin: {user.get('is_admin')} | is_employee: {user.get('is_employee')}")
    except Exception as e:
        print("Error:", e)
