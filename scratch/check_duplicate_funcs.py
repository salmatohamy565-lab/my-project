import re

with open("backend_web/بولا.py", "r", encoding="utf-8") as f:
    code = f.read()

funcs = re.findall(r'def\s+([a_zA-Z0-9_]+)\s*\(', code)
from collections import Counter
counts = Counter(funcs)
duplicates = [f for f, c in counts.items() if c > 1]
print("Duplicate function names:", duplicates)
