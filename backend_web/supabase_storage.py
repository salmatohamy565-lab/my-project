import os
import io
import requests

class SupabaseStorageManager:
    """
    إدارة رفع واسترجاع وحذف الملفات والصور عبر Supabase Storage
    """
    DEFAULT_URL = 'https://kxeqayzxfvoedqvilcmp.supabase.co'

    def __init__(self, supabase_url=None, supabase_key=None):
        raw_url = supabase_url or os.environ.get('SUPABASE_URL', self.DEFAULT_URL)
        self.supabase_url = (raw_url or self.DEFAULT_URL).rstrip('/')
        self.supabase_key = supabase_key or os.environ.get('SUPABASE_KEY') or os.environ.get('SUPABASE_SERVICE_ROLE_KEY', '')
        self.is_configured = bool(self.supabase_url and self.supabase_key)
        
        self._client = None
        if self.is_configured:
            try:
                from supabase import create_client
                self._client = create_client(self.supabase_url, self.supabase_key)
            except Exception:
                pass

    def upload_file(self, bucket_name: str, file_path_in_bucket: str, file_bytes: bytes, content_type: str = 'application/octet-stream') -> str:
        """
        رفع ملف إلى Supabase Storage وإرجاع الرابط المباشر
        """
        if not self.is_configured:
            return self.get_public_url(bucket_name, file_path_in_bucket)

        # محاولة الرفع عبر SDK الرسمي أولاً
        if self._client:
            try:
                # التأكد من وجود الحاوية أولاً، إذا لم تكن موجودة أو المجلد
                self._client.storage.from_(bucket_name).upload(
                    path=file_path_in_bucket,
                    file=file_bytes,
                    file_options={"content-type": content_type, "x-upsert": "true"}
                )
                return self.get_public_url(bucket_name, file_path_in_bucket)
            except Exception as e:
                # إذا حدث خطأ (مثلاً الملف موجود من قبل أو خطأ بالـ SDK)، نجرّب الـ REST API كـ Fallback
                pass

        # Fallback إلى REST API المباشر لضمان العمل 100%
        endpoint = f"{self.supabase_url}/storage/v1/object/{bucket_name}/{file_path_in_bucket}"
        headers = {
            "Authorization": f"Bearer {self.supabase_key}",
            "apiKey": self.supabase_key,
            "Content-Type": content_type,
            "x-upsert": "true"
        }
        res = requests.post(endpoint, headers=headers, data=file_bytes)
        if res.status_code in [200, 201]:
            return self.get_public_url(bucket_name, file_path_in_bucket)
        else:
            # محاولة PUT للتحديث إذا كانت POST لا تدعم upsert بحسب الإصدار
            res_put = requests.put(endpoint, headers=headers, data=file_bytes)
            if res_put.status_code in [200, 201]:
                return self.get_public_url(bucket_name, file_path_in_bucket)
            raise Exception(f"Failed to upload to Supabase Storage: {res.text} / {res_put.text}")

    def get_public_url(self, bucket_name: str, file_path_in_bucket: str) -> str:
        """
        الحصول على الرابط المباشر العام للملف
        """
        if not self.supabase_url:
            return ""
        return f"{self.supabase_url}/storage/v1/object/public/{bucket_name}/{file_path_in_bucket}"

    def download_file(self, bucket_name: str, file_path_in_bucket: str) -> bytes:
        """
        تنزيل الملف كـ bytes من Supabase Storage
        """
        if not self.is_configured:
            raise ValueError("Supabase Storage is not configured.")

        url = self.get_public_url(bucket_name, file_path_in_bucket)
        res = requests.get(url)
        if res.status_code == 200:
            return res.content

        # إذا لم يكن الملف عاماً، نستخدم الـ authenticated endpoint
        endpoint = f"{self.supabase_url}/storage/v1/object/authenticated/{bucket_name}/{file_path_in_bucket}"
        headers = {
            "Authorization": f"Bearer {self.supabase_key}",
            "apiKey": self.supabase_key
        }
        res_auth = requests.get(endpoint, headers=headers)
        if res_auth.status_code == 200:
            return res_auth.content
        raise Exception(f"File not found on Supabase Storage: {file_path_in_bucket}")

    def delete_file(self, bucket_name: str, file_path_in_bucket: str) -> bool:
        """
        حذف ملف من الحاوية
        """
        if not self.is_configured:
            return False

        endpoint = f"{self.supabase_url}/storage/v1/object/{bucket_name}/{file_path_in_bucket}"
        headers = {
            "Authorization": f"Bearer {self.supabase_key}",
            "apiKey": self.supabase_key
        }
        res = requests.delete(endpoint, headers=headers)
        return res.status_code in [200, 204]
