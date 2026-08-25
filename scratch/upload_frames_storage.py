import urllib.request
import os

supabase_url = "https://kxeqayzxfvoedqvilcmp.supabase.co"
anon_key = "sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E"

file_path = "assets/product_images/frames.jpg"
if os.path.exists(file_path):
    with open(file_path, "rb") as f:
        file_bytes = f.read()
    
    url = f"{supabase_url}/storage/v1/object/product_images/frames.jpg"
    req = urllib.request.Request(url, data=file_bytes, method="POST")
    req.add_header("Authorization", f"Bearer {anon_key}")
    req.add_header("apikey", anon_key)
    req.add_header("Content-Type", "image/jpeg")
    req.add_header("x-upsert", "true")
    
    try:
        with urllib.request.urlopen(req) as resp:
            print("Upload status:", resp.status, resp.read().decode('utf-8'))
    except Exception as e:
        print("Upload exception:", e)
else:
    print("File assets/product_images/frames.jpg does not exist!")
