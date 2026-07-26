import importlib.util
import pathlib
import unittest
import uuid

ROOT = pathlib.Path(__file__).resolve().parent
MODULE_PATH = ROOT / 'backend_web' / 'بولا.py'

spec = importlib.util.spec_from_file_location('bola_app', MODULE_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)


class LoginFormTests(unittest.TestCase):
    def setUp(self):
        module.app.config['TESTING'] = True
        self.client = module.app.test_client()

    def test_login_accepts_form_data(self):
        response = self.client.post('/api/login', json={'username': 'admin', 'password': 'admin123'})
        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertEqual(payload['user']['username'], 'admin')


class ProductsPageRouteTests(unittest.TestCase):
    def setUp(self):
        self.app = module.app
        self.app.config['TESTING'] = True
        self.client = self.app.test_client()

    def test_products_page_renders_for_admin(self):
        with self.client.session_transaction() as session:
            session['user_id'] = 1
        response = self.client.get('/products')
        self.assertEqual(response.status_code, 200)
        self.assertIn('منتجاتي', response.get_data(as_text=True))


class CustomerAuthTests(unittest.TestCase):
    def setUp(self):
        module.app.config['TESTING'] = True
        self.client = module.app.test_client()

    def test_customer_can_register_and_login(self):
        username = f'customer_test_{uuid.uuid4().hex[:8]}'
        register_response = self.client.post('/api/customer/register', json={
            'username': username,
            'password': 'StrongPass123',
            'full_name': 'عميل تجريبي',
            'phone': '01000000000'
        })
        self.assertEqual(register_response.status_code, 201)
        payload = register_response.get_json()
        self.assertEqual(payload['user']['role'], 'customer')

        login_response = self.client.post('/api/customer/login', json={
            'username': username,
            'password': 'StrongPass123'
        })
        self.assertEqual(login_response.status_code, 200)
        login_payload = login_response.get_json()
        self.assertEqual(login_payload['user']['username'], username)


if __name__ == '__main__':
    unittest.main()
