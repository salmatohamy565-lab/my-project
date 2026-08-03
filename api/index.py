import sys
import os

# Add backend_web directory to sys.path
backend_dir = os.path.join(os.path.dirname(__file__), '..', 'backend_web')
sys.path.insert(0, os.path.abspath(backend_dir))

from wsgi import app
