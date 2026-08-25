import requests

url_health = "http://192.168.1.16:5001/health"
url_forget = "http://192.168.1.16:5001/api/auth/forget-password"

try:
    r1 = requests.get(url_health, timeout=3)
    print(f"GET {url_health} -> {r1.status_code}, {r1.json()}")
except Exception as e:
    print(f"GET {url_health} -> ERROR: {e}")

try:
    r2 = requests.post(url_forget, json={"email": "salmaa.2004wael@gmail.com"}, timeout=5)
    print(f"POST {url_forget} -> {r2.status_code}, {r2.text[:150]}")
except Exception as e:
    print(f"POST {url_forget} -> ERROR: {e}")
