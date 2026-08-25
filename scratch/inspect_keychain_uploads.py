import os
import glob

brain_dir = r"C:\Users\bolad\.gemini\antigravity-ide\brain"
conv_id = "43826dfa-9167-40eb-ad30-c402c4543677"
user_dir = os.path.join(brain_dir, conv_id, ".user_uploaded")

print(f"User uploaded directory: {user_dir}")
if os.path.exists(user_dir):
    files = sorted(os.listdir(user_dir), key=lambda x: os.path.getmtime(os.path.join(user_dir, x)))
    print("Files sorted by timestamp:")
    for f in files:
        full_p = os.path.join(user_dir, f)
        print(f"  {f} - {os.path.getsize(full_p)} bytes - modified {os.path.getmtime(full_p)}")
