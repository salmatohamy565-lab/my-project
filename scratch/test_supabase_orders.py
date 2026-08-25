import requests
import json

url = "https://kxeqayzxfvoedqvilcmp.supabase.co/rest/v1/orders"
headers = {
    "apikey": "sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E",
    "Authorization": "Bearer sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E",
    "Prefer": "return=representation"
}

payload1 = {
    "customer_name": "Test User",
    "customer_phone": "01000000000",
    "product_ids": "1",
    "items_summary": "Item x1",
    "total_price": 100.0,
    "status": "pending_approval"
}

resp1 = requests.post(url, headers=headers, json=payload1)
print("Insert 1 status:", resp1.status_code)
print("Insert 1 resp:", resp1.text)

get_url = "https://kxeqayzxfvoedqvilcmp.supabase.co/rest/v1/orders?select=id,status,customer_name,total_price,items_summary"
resp2 = requests.get(get_url, headers=headers)
print("Get status:", resp2.status_code)
print("Get resp:", resp2.text)
