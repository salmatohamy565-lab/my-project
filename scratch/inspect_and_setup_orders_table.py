import os
import requests
import json
from dotenv import load_dotenv

load_dotenv('backend_web/.env')
sb_url = os.getenv('SUPABASE_URL')
sb_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or os.getenv('SUPABASE_KEY') or os.getenv('SUPABASE_ANON_KEY')

print(f"Supabase URL: {sb_url}")
headers = {
    "apikey": sb_key,
    "Authorization": f"Bearer {sb_key}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

# 1. Try to fetch orders from Supabase REST API
res = requests.get(f"{sb_url}/rest/v1/orders?select=*", headers=headers)
print(f"Get orders status: {res.status_code}")
print(f"Get orders body: {res.text}")

# 2. Try inserting a sample test order
test_order = {
    "customer_name": "اختبار النظام",
    "customer_phone": "01000000000",
    "product_ids": "1",
    "items_summary": "اختبار أوردر قيد الموافقة",
    "payment_method": "instapay",
    "sender_info": "حساب تجريبي",
    "total_price": 100.0,
    "status": "pending"
}

res_post = requests.post(f"{sb_url}/rest/v1/orders", headers=headers, json=test_order)
print(f"Post test order status: {res_post.status_code}")
print(f"Post test order body: {res_post.text}")
