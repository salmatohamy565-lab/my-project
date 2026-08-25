import requests
import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

url = "http://127.0.0.1:5001/api/customer/phone-login"

test_cases = [
    {"name": "Valid customer (salmaa.2004wael + 01272781686)", "payload": {"username": "salmaa.2004wael", "phone": "01272781686"}},
    {"name": "Valid admin by name (Bola + 01272781686 or phone)", "payload": {"name": "malak", "phone": "01272781686"}},
    {"name": "Invalid phone Mismatch", "payload": {"username": "salmaa.2004wael", "phone": "00000000000"}},
    {"name": "Non-existent user", "payload": {"username": "unknown_user_xyz", "phone": "01272781686"}},
]

for tc in test_cases:
    print(f"\n--- Testing: {tc['name']} ---")
    try:
        r = requests.post(url, json=tc['payload'], timeout=5)
        print("Status:", r.status_code)
        print("Response:", r.text)
    except Exception as e:
        print("Error:", e)
