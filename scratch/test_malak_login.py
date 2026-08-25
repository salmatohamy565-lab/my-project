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

payload = {"p_username": "malak", "p_phone": "01271122860"}

print("\n--- Testing Supabase RPC with 'malak' + '01271122860' ---")
r = requests.post(url, headers=headers, json=payload, timeout=5)
print("Status:", r.status_code)
print("Response:", r.text)
