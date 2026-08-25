import os
import glob

brain_dir = r"C:\Users\bolad\.gemini\antigravity-ide\brain"
conv_id = "43826dfa-9167-40eb-ad30-c402c4543677"

user_dir = os.path.join(brain_dir, conv_id, ".user_uploaded")
print(f"Checking user dir: {user_dir}")

if os.path.exists(user_dir):
    files = os.listdir(user_dir)
    print("Files in user dir:")
    for f in sorted(files):
        full_p = os.path.join(user_dir, f)
        print(f"  {f} - {os.path.getsize(full_p)} bytes - modified {os.path.getmtime(full_p)}")
else:
    print("User dir does not exist! Searching all .user_uploaded dirs...")
    pattern = os.path.join(brain_dir, "*", ".user_uploaded", "*")
    for p in glob.glob(pattern):
        print(p)
