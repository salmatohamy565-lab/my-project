import requests

routes = [
    "/api/forget-password",
    "/api/auth/forget-password",
    "/api/customer/forget-password",
    "/api/forget_password",
    "/api/auth/forget_password",
    "/forget-password",
    "/forget_password",
]

base_url = "https://bola-designs-backend.onrender.com"

for r in routes:
    url = f"{base_url}{r}"
    try:
        res = requests.post(url, json={"email": "bola@boladesigns.com"}, timeout=10)
        print(f"POST {url} -> Status: {res.status_code}, Body: {res.text[:100]}")
    except Exception as e:
        print(f"POST {url} -> Error: {e}")
