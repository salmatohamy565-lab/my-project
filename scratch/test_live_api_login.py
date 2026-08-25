import requests
import sys

sys.stdout.reconfigure(encoding='utf-8')

test_users = [
    "boladesigns111@gmail.com",
    "salmatohamy565@gmail.com",
    "malakmoatsem30@gmail.com",
   
   
]

url = "https://bola-designs-backend.onrender.com/api/login"

print("--- Testing Live Backend Login API ---")
for user in test_users:
    try:
        resp = requests.post(url, json={"username": user, "password": "123456", "remember": True}, timeout=10)
        print(f"User: {user:<30} | Status: {resp.status_code} | Response: {resp.text}")
    except Exception as e:
        print(f"User: {user:<30} | Exception: {e}")
