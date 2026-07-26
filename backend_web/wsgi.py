import sys
import os

# التأكد من إضافة المجلد الحالي للمسار
sys.path.insert(0, os.path.dirname(__file__))

# استيراد تطبيق Flask من ملف بولا.py
try:
    from بولا import app
except ImportError:
    # استيراد بديل إذا كانت هناك مشكلة في تشفير الاسم العربي
    import importlib.util
    file_path = os.path.join(os.path.dirname(__file__), 'بولا.py')
    spec = importlib.util.spec_from_file_location("bola_app", file_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    app = module.app

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    app.run(host='0.0.0.0', port=port)
