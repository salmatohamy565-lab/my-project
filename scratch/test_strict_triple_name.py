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
    {"name": "Single word customer 'أحمد'", "payload": {"p_username": "أحمد", "p_phone": ""}},
    {"name": "Two word customer 'أحمد محمد'", "payload": {"p_username": "أحمد محمد", "p_phone": ""}},
    {"name": "Triple word customer 'أحمد محمد محمود'", "payload": {"p_username": "أحمد محمد محمود", "p_phone": ""}},
    {"name": "Admin 'admin_bola_01'", "payload": {"p_username": "admin_bola_01", "p_phone": ""}},
    {"name": "Employee 'emp_malak_101'", "payload": {"p_username": "emp_malak_101", "p_phone": ""}},
]

for tc in test_cases:
    print(f"\n--- Testing: {tc['name']} ---")
    try:
        r = requests.post(url, headers=headers, json=tc['payload'], timeout=5)
        print(f"Status: {r.status_code} | Body: {r.text}")
    except Exception as e:
        print("Error:", e)
