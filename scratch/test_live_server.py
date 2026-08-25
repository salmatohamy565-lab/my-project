import requests

try:
    print("Testing Render Live Server Health Endpoint...")
    res = requests.get("https://bola-designs-backend.onrender.com/health", timeout=30)
    print(f"Render Health Status Code: {res.status_code}")
    print(f"Render Health Body: {res.text}")
except Exception as e:
    print(f"Render Health Exception: {e}")

try:
    print("\nTesting Render Live Server API Products Endpoint...")
    res2 = requests.get("https://bola-designs-backend.onrender.com/api/products", timeout=30)
    print(f"Render Products Status Code: {res2.status_code}")
    print(f"Render Products Count: {len(res2.json()) if res2.status_code == 200 else res2.text}")
except Exception as e:
    print(f"Render Products Exception: {e}")
