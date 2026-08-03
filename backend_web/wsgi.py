import sys
import os

sys.path.insert(0, os.path.dirname(__file__))

try:
    from bola_main import app
except ImportError:
    import importlib.util
    file_path = os.path.join(os.path.dirname(__file__), 'بولا.py')
    spec = importlib.util.spec_from_file_location("bola_app", file_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    app = module.app

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    app.run(host='0.0.0.0', port=port)
