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
    {"name": "Valid login (salmaa.2004wael + 01272781686)", "payload": {"p_username": "salmaa.2004wael", "p_phone": "01272781686"}},
    {"name": "Wrong phone number", "payload": {"p_username": "salmaa.2004wael", "p_phone": "00000000000"}},
]

for tc in test_cases:
    print(f"\n--- Testing Supabase Native RPC: {tc['name']} ---")
    try:
        r = requests.post(url, headers=headers, json=tc['payload'], timeout=5)
        print("Status:", r.status_code)
        print("Response:", r.text)
    except Exception as e:
        print("Error:", e)
