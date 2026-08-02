with open(r'c:\Users\bolad\Desktop\bola app\backend_web\بولا.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()
for i, line in enumerate(lines):
    if 'user_allowed' in line:
        print(f"{i+1}: {line.strip()}")
