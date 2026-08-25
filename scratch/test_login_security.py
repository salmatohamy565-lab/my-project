import requests
import sys

sys.stdout.reconfigure(encoding='utf-8')
base_url = "http://127.0.0.1:5001"

# 1. Test wrong password
print("--- 1. Testing Wrong Password ---")
res1 = requests.post(f"{base_url}/api/customer/login", json={
    "username": "Bola",
    "password": "wrong_password_9999"
})
print(f"Wrong Password Response Code: {res1.status_code}")
print(f"Wrong Password Response Body: {res1.text}\n")

# 2. Test correct password
print("--- 2. Testing Correct Password ---")
res2 = requests.post(f"{base_url}/api/customer/login", json={
    "username": "Bola",
    "password": "123456"
})
print(f"Correct Password Response Code: {res2.status_code}")
print(f"Correct Password User: {res2.json().get('user', {}).get('username')}\n")
