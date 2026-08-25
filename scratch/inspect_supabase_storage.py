import requests
import json
import os
from dotenv import load_dotenv

load_dotenv('backend_web/.env')
sb_url = os.getenv('SUPABASE_URL')
sb_key = os.getenv('SUPABASE_KEY') or os.getenv('SUPABASE_ANON_KEY')

headers = {
    "apikey": sb_key,
    "Authorization": f"Bearer {sb_key}"
}

res = requests.get(f"{sb_url}/storage/v1/bucket", headers=headers)
print(f"Storage Buckets Status: {res.status_code}")
print(f"Storage Buckets Body: {res.text}")
