import requests

url = "https://kxeqayzxfvoedqvilcmp.supabase.co/rest/v1/orders?select=*"
anon_key = "sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E"

headers = {
    "apikey": anon_key,
    "Authorization": f"Bearer {anon_key}",
    "Content-Type": "application/json"
}

print("Executing direct unauthenticated GET request to /rest/v1/orders using Anon Key only...")
res = requests.get(url, headers=headers)

print(f"Response Status Code: {res.status_code}")
print(f"Response Body: {res.text}")

if res.status_code == 200:
    data = res.json()
    if isinstance(data, list):
        print(f"RESULT: Returned {len(data)} items.")
        if len(data) == 0:
            print("[TEST PASSED] RLS successfully blocked unauthenticated access and returned 0 rows!")
        else:
            print("[TEST FAILED] Rows were returned without authentication!")
else:
    print(f"[TEST PASSED] RLS blocked access with status code: {res.status_code}")
