with open("backend_web/بولا.py", "r", encoding="utf-8") as f:
    lines = f.readlines()

for idx, line in enumerate(lines):
    if "password_hash" in line or "set_password" in line or "password" in line:
        if "def " in line or "=" in line:
            print(f"Line {idx+1}: {line.strip()}")
