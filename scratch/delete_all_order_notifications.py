import urllib.request
import json

url = "https://kxeqayzxfvoedqvilcmp.supabase.co/rest/v1/notifications"
headers = {
    "apikey": "sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E",
    "Authorization": "Bearer sb_publishable_n2OnkbUJFsVNTdRdDeuxUA_wxUe7z4E",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

# Delete all notifications from Supabase notifications table to clear all account notifications cleanly
req_del = urllib.request.Request(
    f"{url}?id=gt.0",
    headers=headers,
    method="DELETE"
)

try:
    with urllib.request.urlopen(req_del) as resp:
        print("DELETE ALL NOTIFICATIONS RESPONSE STATUS:", resp.status)
except Exception as e:
    print("DELETE ALL ERROR:", e)
