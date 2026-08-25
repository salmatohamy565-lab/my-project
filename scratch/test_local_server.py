import requests

url = "http://127.0.0.1:5001/api/auth/forget-password"
try:
    res = requests.post(url, json={"email": "bola@boladesigns.com"}, timeout=20)
    print(f"Local Server Status: {res.status_code}, Body: {res.text}")
except Exception as e:
    print(f"Local Server Connection Error: {e}")
