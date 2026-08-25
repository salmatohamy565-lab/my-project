import jwt
import time

# Supabase project ref
project_ref = "kxeqayzxfvoedqvilcmp"

# Standard payload for Supabase anon role
payload = {
    "iss": "supabase",
    "ref": project_ref,
    "role": "anon",
    "iat": int(time.time()),
    "exp": int(time.time()) + (10 * 365 * 24 * 3600)  # 10 years
}

# Standard JWT Secret or test
print("Payload:", payload)
