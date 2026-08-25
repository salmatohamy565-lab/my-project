import requests

url = "https://kxeqayzxfvoedqvilcmp.supabase.co/rest/v1/orders?id=eq.130"
headers = {
    "apikey": "sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E",
    "Authorization": "Bearer sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E",
    "Prefer": "return=representation"
}

payload = {
    "status": "preparing"
}

resp = requests.patch(url, headers=headers, json=payload)
print("UPDATE status code:", resp.status_code)
print("UPDATE response:", resp.text)
