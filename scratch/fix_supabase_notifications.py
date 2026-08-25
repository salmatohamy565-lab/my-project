import urllib.request
import json

url = "https://kxeqayzxfvoedqvilcmp.supabase.co/rest/v1/notifications"
headers = {
    "apikey": "sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E",
    "Authorization": "Bearer sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

# 1. Update is_read = True for row 242 and all false rows
req_patch = urllib.request.Request(
    f"{url}?is_read=eq.false",
    data=json.dumps({"is_read": True}).encode('utf-8'),
    headers=headers,
    method="PATCH"
)
try:
    with urllib.request.urlopen(req_patch) as resp:
        print("PATCH is_read response:", resp.status)
except Exception as e:
    print("PATCH error:", e)

# Delete order notifications
for pattern in ["%D8%A7%D8%B3%D8%AA%D9%84%D8%A7%D9%85%", "%D8%B7%D9%84%D8%A9%D9%83%25", "%D8%A5%D8%B5%D8%AF%D8%A7%D8%B1%25"]:
    req_del = urllib.request.Request(
        f"{url}?title=like.{pattern}",
        headers=headers,
        method="DELETE"
    )
    try:
        with urllib.request.urlopen(req_del) as resp:
            print(f"DELETE title pattern {pattern} status:", resp.status)
    except Exception as e:
        print(f"DELETE title error:", e)
