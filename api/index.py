import sys
import os

backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend_web'))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

try:
    from wsgi import app
except Exception as e:
    from flask import Flask, jsonify
    app = Flask(__name__)
    
    @app.route('/', defaults={'path': ''})
    @app.route('/<path:path>')
    def catch_all(path):
        return jsonify({
            "error": "Server initialization error",
            "details": str(e)
        }), 500
