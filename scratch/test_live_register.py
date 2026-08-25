import requests
import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

url = "https://bola-designs-backend.onrender.com/api/customer/register"
payload = {
    "name": "malak",
    "email": "malakanti332@gmail.com",
    "phone": "01271122860",
    "password": "password123",
    "username": "malakanti332"
}

print(f"Sending POST to {url}...")
try:
    res = requests.post(url, json=payload, timeout=10)
    print("Status Code:", res.status_code)
    print("Response Body:", res.text)
except Exception as e:
    print("Request Error:", e)
