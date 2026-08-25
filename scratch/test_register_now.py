import requests
import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

url = "http://127.0.0.1:5001/api/customer/register"
payload = {
    "name": "malak",
    "email": "malakanti332@gmail.com",
    "phone": "01271122860",
    "password": "password123",
    "username": "malakanti332"
}

print(f"Sending POST to {url}...")
try:
    res = requests.post(url, json=payload, timeout=5)
    print("Status Code:", res.status_code)
    print("Response Body:", res.text)
except Exception as e:
    print("Request Error:", e)
