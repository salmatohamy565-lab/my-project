import requests
import sys
sys.stdout.reconfigure(encoding='utf-8')

urls = [
    "http://127.0.0.1:5001/health",
    "http://127.0.0.1:5001/api/customer/register",
]

for url in urls:
    try:
        if "register" in url:
            r = requests.post(url, json={"username": "test", "email": "test@test.com", "password": "123"}, timeout=2)
        else:
            r = requests.get(url, timeout=2)
        print(f"[SUCCESS {r.status_code}] {url} -> {r.text[:100]}")
    except Exception as e:
        print(f"[OFFLINE] {url} -> {e}")
