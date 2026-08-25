import requests

url = "https://bola-designs-backend.onrender.com/api/orders"
try:
    resp = requests.get(url, timeout=10)
    print("Backend GET orders status:", resp.status_code)
    print("Backend GET orders resp:", resp.text[:500])
except Exception as e:
    print("Backend GET error:", e)
