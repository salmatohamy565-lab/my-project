import requests
import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

base_url = "https://bola-designs-backend.onrender.com"

endpoints = [
    "/health",
    "/api/health",
    "/customer/register",
    "/api/customer/register",
    "/register",
    "/api/register",
    "/api/customer/login",
    "/login"
]

for ep in endpoints:
    try:
        url = base_url + ep
        if "register" in ep or "login" in ep:
            r = requests.post(url, json={"username": "test", "password": "123"}, timeout=5)
        else:
            r = requests.get(url, timeout=5)
        print(f"[{r.status_code}] {url} -> {r.text[:100]}")
    except Exception as e:
        print(f"[ERR] {url} -> {e}")
