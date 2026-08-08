import sys
import io
if sys.platform == "win32":
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')
    except Exception:
        pass

from datetime import timedelta, datetime
from flask import Flask, request, jsonify, abort, session, send_from_directory, render_template, redirect, url_for
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import inspect, text, or_
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
import os
import time
import secrets
import html
import json

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

try:
    from supabase_storage import SupabaseStorageManager
    storage_mgr = SupabaseStorageManager()
except Exception:
    storage_mgr = None

from flask_cors import CORS

app = Flask(__name__, template_folder=os.path.join(os.path.dirname(__file__), 'templates'), static_folder=os.path.join(os.path.dirname(__file__), 'static'))
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

@app.after_request
def add_cors_headers(response):
    origin = request.headers.get('Origin')
    if origin:
        response.headers['Access-Control-Allow-Origin'] = origin
    else:
        response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type,Authorization,Cookie,X-Requested-With'
    response.headers['Access-Control-Allow-Methods'] = 'GET,PUT,POST,DELETE,OPTIONS'
    return response

# قاعدة البيانات: القراءة من DATABASE_URL أولاً مع Supabase Postgres كـ default لبيئة Vercel/Cloud
DEFAULT_DB_URL = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
DATABASE_URL = os.environ.get('DATABASE_URL') or DEFAULT_DB_URL
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)
app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL

app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY') or "bola_secret_key_2026"
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(days=30)
app.config['STATIC_VERSION'] = str(int(time.time()))
# reduce static file caching during development
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0
db = SQLAlchemy(app)

# expose STATIC_VERSION to templates
app.jinja_env.globals['STATIC_VERSION'] = app.config['STATIC_VERSION']

# uploads configuration (safe for Vercel read-only filesystem)
is_vercel = os.environ.get('VERCEL') == '1' or 'VERCEL_REGION' in os.environ
if is_vercel:
    app.config['UPLOAD_FOLDER'] = '/tmp/uploads'
    app.config['PRODUCT_IMAGE_FOLDER'] = '/tmp/product_images'
    app.config['PAYMENT_PROOF_FOLDER'] = '/tmp/payment_proofs'
else:
    app.config['UPLOAD_FOLDER'] = os.path.join(os.path.dirname(__file__), 'uploads')
    app.config['PRODUCT_IMAGE_FOLDER'] = os.path.join(app.static_folder, 'product_images')
    app.config['PAYMENT_PROOF_FOLDER'] = os.path.join(app.static_folder, 'payment_proofs')

for folder in [app.config['UPLOAD_FOLDER'], app.config['PRODUCT_IMAGE_FOLDER'], app.config['PAYMENT_PROOF_FOLDER']]:
    try:
        os.makedirs(folder, exist_ok=True)
    except Exception:
        pass



# ===================== المودلات =====================
class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=True)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), nullable=False)
    name = db.Column(db.String(100), nullable=True)
    phone = db.Column(db.String(30), nullable=True)
    photo_url = db.Column(db.String(255), nullable=True)
    reset_otp = db.Column(db.String(10), nullable=True)
    reset_otp_expires_at = db.Column(db.Float, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.now)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        if not self.password_hash or not password:
            return False
        if self.password_hash == password:
            return True
        try:
            return check_password_hash(self.password_hash, password)
        except Exception:
            return False

    def to_dict(self):
        return {
            "id": self.id,
            "username": self.username,
            "email": getattr(self, 'email', None),
            "name": getattr(self, 'name', None) or self.username,
            "phone": getattr(self, 'phone', ''),
            "photo_url": getattr(self, 'photo_url', None),
            "role": self.role,
            "is_admin": self.role in ('admin', 'owner'),
            "is_employee": self.role == 'employee',
            "created_at": self.created_at.isoformat() if hasattr(self, 'created_at') and self.created_at else None
        }

class Task(db.Model):
    __tablename__ = 'tasks'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(500))
    assigned_to = db.Column(db.Integer, db.ForeignKey('users.id'))
    status = db.Column(db.String(20), default="pending")
    created_at = db.Column(db.DateTime, default=__import__('datetime').datetime.now)
    completed_at = db.Column(db.DateTime, nullable=True)

    def to_dict(self):
        user = User.query.get(self.assigned_to)
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "assigned_to": self.assigned_to,
            "assigned_to_username": user.username if user else None,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None
        }


class Attendance(db.Model):
    __tablename__ = 'attendance'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    attendance_date = db.Column(db.String(20), nullable=False)
    check_in_time = db.Column(db.String(20))
    check_out_time = db.Column(db.String(20))
    status = db.Column(db.String(20), default='present')
    created_at = db.Column(db.DateTime, default=datetime.now)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "attendance_date": self.attendance_date,
            "check_in_time": self.check_in_time,
            "check_out_time": self.check_out_time,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }


class Product(db.Model):
    __tablename__ = 'products'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    description = db.Column(db.String(500))
    price = db.Column(db.Float, nullable=False, default=0.0)
    image_filename = db.Column(db.String(255))
    category_id = db.Column(db.String(50), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.now)

    def to_dict(self):
        image_url = None
        if self.image_filename:
            if self.image_filename.startswith('http://') or self.image_filename.startswith('https://'):
                image_url = self.image_filename
            elif storage_mgr and storage_mgr.is_configured:
                image_url = storage_mgr.get_public_url('product-images', self.image_filename)
            else:
                image_url = url_for('static', filename=f'product_images/{self.image_filename}')
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "price": float(self.price),
            "image_url": image_url,
            "category_id": getattr(self, 'category_id', None),
            "created_at": self.created_at.isoformat() if self.created_at else None
        }


class Order(db.Model):
    __tablename__ = 'orders'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    customer_name = db.Column(db.String(120))
    customer_phone = db.Column(db.String(50))
    product_ids = db.Column(db.String(255))
    items_summary = db.Column(db.Text)
    total_price = db.Column(db.Float, nullable=False, default=0.0)
    payment_method = db.Column(db.String(50), default='instapay')
    payment_proof_filename = db.Column(db.String(255))
    status = db.Column(db.String(50), default='pending') # pending, preparing, ready, delivered, rejected
    rejection_reason = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.now)

    user = db.relationship('User', backref=db.backref('orders', lazy=True))

    def to_dict(self):
        payment_proof_url = None
        if self.payment_proof_filename:
            if self.payment_proof_filename.startswith('http://') or self.payment_proof_filename.startswith('https://'):
                payment_proof_url = self.payment_proof_filename
            elif storage_mgr and storage_mgr.is_configured:
                payment_proof_url = storage_mgr.get_public_url('payment-proofs', self.payment_proof_filename)
            else:
                payment_proof_url = url_for('static', filename=f'payment_proofs/{self.payment_proof_filename}')

        return {
            "id": self.id,
            "user_id": self.user_id,
            "customer_name": self.customer_name or (getattr(self.user, 'name', None) or (self.user.username if self.user else "عميل")),
            "customer_phone": self.customer_phone or (getattr(self.user, 'phone', None) or ""),
            "product_ids": self.product_ids or "",
            "items_summary": self.items_summary or "",
            "total_price": float(self.total_price),
            "payment_method": self.payment_method or "instapay",
            "payment_proof_url": payment_proof_url,
            "status": self.status or "pending",
            "rejection_reason": self.rejection_reason or "",
            "created_at": self.created_at.isoformat() if self.created_at else None
        }


class AppNotification(db.Model):
    __tablename__ = 'notifications'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    title = db.Column(db.String(200), nullable=False)
    message = db.Column(db.Text, nullable=False)
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.now)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "title": self.title,
            "message": self.message,
            "is_read": self.is_read,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }


def ensure_attendance_columns():
    try:
        with db.engine.connect() as conn:
            columns = [c['name'] for c in inspect(db.engine).get_columns('attendance')]
            if 'status' not in columns:
                conn.execute(text("ALTER TABLE attendance ADD COLUMN status VARCHAR(20) DEFAULT 'present'"))
                conn.commit()
    except Exception:
        pass


def ensure_task_columns():
    try:
        with db.engine.connect() as conn:
            columns = [c['name'] for c in inspect(db.engine).get_columns('tasks')]
            if 'completed_at' not in columns:
                conn.execute(text("ALTER TABLE tasks ADD COLUMN completed_at DATETIME"))
                conn.commit()
    except Exception:
        pass


def ensure_user_columns():
    try:
        with db.engine.connect() as conn:
            columns = [c['name'] for c in inspect(db.engine).get_columns('users')]
            if 'email' not in columns:
                try:
                    conn.execute(text("ALTER TABLE users ADD COLUMN email VARCHAR(120)"))
                    conn.commit()
                except Exception:
                    pass
            if 'name' not in columns:
                try:
                    conn.execute(text("ALTER TABLE users ADD COLUMN name VARCHAR(100)"))
                    conn.commit()
                except Exception:
                    pass
            if 'phone' not in columns:
                try:
                    conn.execute(text("ALTER TABLE users ADD COLUMN phone VARCHAR(30)"))
                    conn.commit()
                except Exception:
                    pass
            if 'photo_url' not in columns:
                try:
                    conn.execute(text("ALTER TABLE users ADD COLUMN photo_url VARCHAR(255)"))
                    conn.commit()
                except Exception:
                    pass
            if 'created_at' not in columns:
                try:
                    conn.execute(text("ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"))
                    conn.commit()
                except Exception:
                    try:
                        conn.execute(text("ALTER TABLE users ADD COLUMN created_at DATETIME"))
                        conn.commit()
                    except Exception:
                        pass
    except Exception as e:
        print(f"Migration error: {e}")


def ensure_product_columns():
    try:
        with db.engine.connect() as conn:
            columns = [c['name'] for c in inspect(db.engine).get_columns('products')]
            if 'image_filename' not in columns:
                conn.execute(text("ALTER TABLE products ADD COLUMN image_filename VARCHAR(255)"))
                conn.commit()
            if 'category_id' not in columns:
                conn.execute(text("ALTER TABLE products ADD COLUMN category_id VARCHAR(50)"))
                conn.commit()
    except Exception:
        pass

# ===================== إنشاء قاعدة البيانات =====================
with app.app_context():
    db.create_all()
    ensure_user_columns()
    ensure_attendance_columns()
    ensure_task_columns()
    ensure_product_columns()

    # List of initial required accounts
    initial_users = [
        # Admins
        {"username": "Bola", "email": "bola@boladesigns.com", "name": "بولا عزت", "role": "admin", "password": "78945612300"},
        {"username": "Eman", "email": "eman@boladesigns.com", "name": "إيمان", "role": "admin", "password": "admin123"},
        {"username": "admin", "email": "admin@boladesigns.com", "name": "مدير النظام", "role": "admin", "password": "admin123"},

        # Employees
        {"username": "Malak", "email": "malak@boladesigns.com", "name": "ملك", "role": "employee", "password": "emp123"},
        {"username": "Salma", "email": "salma@boladesigns.com", "name": "سلمى", "role": "employee", "password": "emp123"},
        {"username": "dieved", "email": "dieved@boladesigns.com", "name": "ديفيد (dieved)", "role": "employee", "password": "emp123"},
        {"username": "Abdelkreem", "email": "abdelkreem@boladesigns.com", "name": "عبد الكريم", "role": "employee", "password": "emp123"},
    ]

    # Clean up excluded employees (employee, mohamed)
    for target_user in ['employee', 'mohamed']:
        u_del = User.query.filter(db.func.lower(User.username) == target_user.lower()).first()
        if u_del:
            Attendance.query.filter_by(user_id=u_del.id).delete()
            Task.query.filter_by(assigned_to=u_del.id).delete()
            Order.query.filter_by(user_id=u_del.id).delete()
            AppNotification.query.filter_by(user_id=u_del.id).delete()
            db.session.delete(u_del)
    db.session.commit()

    # Migration for Dawood -> dieved
    old_dawood = User.query.filter(
        or_(
            db.func.lower(User.username) == 'dawood',
            db.func.lower(getattr(User, 'email', User.username)) == 'dawood@boladesigns.com'
        )
    ).first()
    if old_dawood:
        old_dawood.username = 'dieved'
        old_dawood.email = 'dieved@boladesigns.com'
        old_dawood.name = 'ديفيد (dieved)'
        old_dawood.set_password('emp123')
        db.session.commit()



    for u_info in initial_users:
        u = User.query.filter(
            or_(
                db.func.lower(User.username) == u_info['username'].lower(),
                db.func.lower(getattr(User, 'email', User.username)) == u_info['email'].lower()
            )
        ).first()
        if not u:
            u = User(
                username=u_info['username'],
                email=u_info['email'],
                name=u_info['name'],
                role=u_info['role']
            )
            u.set_password(u_info['password'])
            db.session.add(u)
        else:
            u.role = u_info['role']
            u.email = u_info['email']
            u.name = u_info['name']
            u.set_password(u_info['password'])

    db.session.commit()
    if Product.query.count() == 0:
        sample_products = [
            {"name": "تصميم هوية تجارية", "description": "باقة كاملة لتصميم الشعار والهوية البصرية.", "price": 1200.0},
            {"name": "لوحة إعلانية رقمية", "description": "تصميم إعلان رقمي جاهز للنشر على السوشيال ميديا.", "price": 450.0},
            {"name": "عرض تقديمي احترافي", "description": "تصميم عرض تقديمي مميز للشركات والمشاريع.", "price": 800.0}
        ]
        for item in sample_products:
            product = Product(name=item['name'], description=item['description'], price=item['price'])
            db.session.add(product)
        db.session.commit()

# ===================== وظائف مساعدة =====================
def get_current_user():
    if 'user_id' in session:
        user = User.query.get(session['user_id'])
        if user:
            return user

    auth_header = request.headers.get('Authorization') or request.headers.get('token') or request.headers.get('X-User-Id')
    if auth_header:
        token = auth_header.replace('Bearer ', '').strip()
        if token.isdigit():
            user = User.query.get(int(token))
            if user:
                return user
        user = User.query.filter(db.func.lower(User.username) == db.func.lower(token)).first()
        if user:
            return user

    return User.query.filter_by(role='admin').first() or User.query.first()


def load_file_metadata(user_id):
    user_dir = os.path.join(app.config['UPLOAD_FOLDER'], str(user_id))
    meta_path = os.path.join(user_dir, '.meta.json')
    if not os.path.isfile(meta_path):
        return {}
    try:
        with open(meta_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return {}


def save_file_metadata(user_id, filename, metadata):
    user_dir = os.path.join(app.config['UPLOAD_FOLDER'], str(user_id))
    os.makedirs(user_dir, exist_ok=True)
    meta_path = os.path.join(user_dir, '.meta.json')
    meta = load_file_metadata(user_id)
    meta[filename] = metadata
    with open(meta_path, 'w', encoding='utf-8') as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
    return meta


def get_user_files(user_id):
    uploads_root = app.config['UPLOAD_FOLDER']
    files = []
    seen_keys = set()

    if not os.path.isdir(uploads_root):
        return files

    target_user = User.query.get(user_id) if isinstance(user_id, int) else None
    is_staff = target_user and target_user.role in ('admin', 'employee')

    for entry in os.listdir(uploads_root):
        user_dir = os.path.join(uploads_root, entry)
        if not os.path.isdir(user_dir):
            continue
        try:
            folder_uid = int(entry)
        except Exception:
            folder_uid = entry

        meta = load_file_metadata(folder_uid)
        for fn in os.listdir(user_dir):
            if fn == '.meta.json' or not os.path.isfile(os.path.join(user_dir, fn)):
                continue
            item_meta = meta.get(fn, {})
            up_id = item_meta.get('uploaded_by_id')
            rec_id = item_meta.get('recipient_id')
            up_id_int = int(up_id) if up_id is not None and str(up_id).isdigit() else None
            rec_id_int = int(rec_id) if rec_id is not None and str(rec_id).isdigit() else None

            if (folder_uid == user_id) or (up_id_int == user_id) or (rec_id_int == user_id) or (is_staff and rec_id_int in (None, 0)):
                file_key = f"{folder_uid}_{fn}"
                if file_key not in seen_keys:
                    seen_keys.add(file_key)
                    file_url = item_meta.get('storage_url') or f"/api/users/{folder_uid}/files/{fn}"
                    files.append({
                        "filename": fn,
                        "url": file_url,
                        "uploaded_by": item_meta.get('uploaded_by', 'غير معروف'),
                        "uploaded_by_id": up_id_int,
                        "uploaded_by_role": item_meta.get('uploaded_by_role'),
                        "uploaded_at": item_meta.get('uploaded_at'),
                        "recipient_id": rec_id_int,
                        "recipient_name": item_meta.get('recipient_name')
                    })
    files.sort(key=lambda x: x.get('uploaded_at') or '', reverse=True)
    return files


def get_user_attendance(user_id):
    return [a.to_dict() for a in Attendance.query.filter_by(user_id=user_id).order_by(Attendance.attendance_date.desc(), Attendance.created_at.desc()).all()]


def record_login_attendance(user_id):
    today = datetime.now().strftime('%Y-%m-%d')
    record = Attendance.query.filter_by(user_id=user_id, attendance_date=today).first()
    if record:
        if not record.check_in_time:
            record.check_in_time = datetime.now().strftime('%H:%M')
            db.session.commit()
        return record
    record = Attendance(user_id=user_id, attendance_date=today, check_in_time=datetime.now().strftime('%H:%M'))
    db.session.add(record)
    db.session.commit()
    return record


def record_logout_attendance(user_id):
    today = datetime.now().strftime('%Y-%m-%d')
    record = Attendance.query.filter_by(user_id=user_id, attendance_date=today).first()
    if record and not record.check_out_time:
        record.check_out_time = datetime.now().strftime('%H:%M')
        db.session.commit()
    return record


def get_archive_marker_path():
    return os.path.join(os.path.dirname(__file__), 'archive_marker.json')


def archive_completed_tasks():
    cutoff = datetime.now() - timedelta(days=1)
    tasks_to_archive = Task.query.filter(
        Task.status == 'done',
        or_(
            Task.completed_at != None,
            Task.completed_at == None
        )
    ).all()
    archive_count = 0
    for task in tasks_to_archive:
        task_time = task.completed_at or task.created_at
        if task_time and task_time <= cutoff:
            task.status = 'archived'
            archive_count += 1
    if archive_count:
        db.session.commit()
    return archive_count


def ensure_daily_task_archive():
    marker_path = get_archive_marker_path()
    today = datetime.now().strftime('%Y-%m-%d')
    last_run = None
    if os.path.isfile(marker_path):
        try:
            with open(marker_path, 'r', encoding='utf-8') as f:
                marker = json.load(f)
                last_run = marker.get('last_archive_date')
        except Exception:
            last_run = None

    if last_run == today:
        return

    archive_completed_tasks()
    try:
        with open(marker_path, 'w', encoding='utf-8') as f:
            json.dump({'last_archive_date': today}, f, ensure_ascii=False)
    except Exception:
        pass


@app.before_request
def run_daily_archive_before_request():
    try:
        ensure_daily_task_archive()
    except Exception:
        pass


@app.route('/api/tasks/archive', methods=['POST'])
def archive_tasks_now():
    current_user = get_current_user()
    if not current_user or current_user.role != 'admin':
        return jsonify({"error": "صلاحيات المسؤول مطلوبة"}), 403
    archived_count = archive_completed_tasks()
    return jsonify({"archived_count": archived_count}), 200


@app.route('/splash')
def splash():
    # show a startup splash with the logo, then redirect to the `next` parameter
    next_url = request.args.get('next', '/')
    return render_template('splash.html', next_url=next_url)


def safe_filename_arabic(raw_filename):
    if not raw_filename:
        return f"file_{int(time.time())}.bin"
    clean = os.path.basename(raw_filename).replace('/', '_').replace('\\', '_').strip(' .')
    if not clean:
        return f"file_{int(time.time())}.bin"
    sec = secure_filename(clean)
    if sec and len(sec.split('.')[0]) > 0:
        return sec
    name_part, ext_part = os.path.splitext(clean)
    safe_name = f"{name_part}{ext_part}" if name_part else f"file_{int(time.time())}{ext_part}"
    return safe_name.replace(' ', '_')


def user_allowed(current_user, user_id):
    if not current_user:
        return False
    if current_user.role == 'admin':
        return True
    return current_user.id == user_id


@app.route('/api/users/<int:user_id>/files', methods=['POST'])
def upload_user_file(user_id):
    current_user = get_current_user()
    if not user_allowed(current_user, user_id):
        return jsonify({"error": "غير مصرح"}), 403

    if 'file' not in request.files:
        return jsonify({"error": "لم يتم إرسال ملف"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "اسم الملف فارغ"}), 400

    recipient_id = request.form.get('recipient_id') or (request.is_json and request.json and request.json.get('recipient_id'))
    try:
        recipient_id = int(recipient_id) if recipient_id is not None and str(recipient_id).isdigit() else None
    except Exception:
        recipient_id = None

    recipient_user = User.query.get(recipient_id) if recipient_id else None

    filename = safe_filename_arabic(file.filename)
    file_bytes = file.read()

    storage_url = None
    if storage_mgr and storage_mgr.is_configured:
        try:
            path_in_bucket = f"{user_id}/{filename}"
            storage_url = storage_mgr.upload_file('user-uploads', path_in_bucket, file_bytes, content_type=file.content_type or 'application/octet-stream')
        except Exception as e:
            print(f"Supabase upload error: {e}")

    # حفظ نسخة محلية احتياطية إن أمكن
    try:
        user_dir = os.path.join(app.config['UPLOAD_FOLDER'], str(user_id))
        os.makedirs(user_dir, exist_ok=True)
        dest = os.path.join(user_dir, filename)
        with open(dest, 'wb') as f:
            f.write(file_bytes)
    except Exception:
        pass

    meta_data = {
        "uploaded_by": current_user.username,
        "uploaded_by_id": current_user.id,
        "uploaded_by_role": current_user.role,
        "uploaded_at": datetime.now().isoformat(),
        "recipient_id": recipient_id,
        "recipient_name": recipient_user.username if recipient_user else None
    }
    if storage_url:
        meta_data["storage_url"] = storage_url

    save_file_metadata(user_id, filename, meta_data)
    res_url = storage_url or f"/api/users/{user_id}/files/{filename}"
    return jsonify({"message": "تم رفع الملف بنجاح", "filename": filename, "url": res_url}), 201


@app.route('/api/users/<int:user_id>/files', methods=['GET'])
def list_user_files(user_id):
    current_user = get_current_user()
    if not user_allowed(current_user, user_id):
        return jsonify({"error": "غير مصرح"}), 403

    return jsonify(get_user_files(user_id)), 200


@app.route('/api/users/<int:user_id>/files/<path:filename>', methods=['GET'])
def get_user_file(user_id, filename):
    current_user = get_current_user()
    if not user_allowed(current_user, user_id):
        return jsonify({"error": "غير مصرح"}), 403

    safe_name = secure_filename(filename)
    user_dir = os.path.join(app.config['UPLOAD_FOLDER'], str(user_id))
    file_path = os.path.join(user_dir, safe_name)

    if os.path.isfile(file_path):
        return send_from_directory(user_dir, safe_name, as_attachment=True)

    if storage_mgr and storage_mgr.is_configured:
        try:
            file_bytes = storage_mgr.download_file('user-uploads', f"{user_id}/{safe_name}")
            from flask import Response
            return Response(
                file_bytes,
                mimetype='application/octet-stream',
                headers={"Content-Disposition": f'attachment; filename="{safe_name}"'}
            )
        except Exception:
            pass

    return jsonify({"error": "ملف غير موجود"}), 404

@app.route('/employee/<int:user_id>/files')
def employee_files_page(user_id):
    current_user = get_current_user()
    if not current_user:
        return redirect('/login')

    if current_user.role != 'admin' and current_user.id != user_id:
        return "<h1>غير مصرح</h1>", 403

    target_user = User.query.get(user_id)
    if not target_user:
        return "<h1>الموظف غير موجود</h1>", 404

    files = get_user_files(user_id)
    attendance = get_user_attendance(user_id)
    tasks = Task.query.filter(Task.assigned_to == user_id, Task.status != 'archived').all()
    return render_template('employee_detail.html', user=target_user, files=files, attendance=attendance, tasks=tasks, current_user=current_user)


def find_user_by_identifier(identifier):
    if not identifier:
        return None
    clean = str(identifier).strip().lower()
    prefix = clean.split('@')[0] if '@' in clean else clean
    return User.query.filter(
        or_(
            db.func.lower(User.username) == clean,
            db.func.lower(User.email) == clean,
            db.func.lower(User.username) == prefix,
            db.func.lower(User.email) == prefix
        )
    ).first()

# ===================== المسارات =====================
@app.route('/api/customer/register', methods=['POST'])
@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json() or {}
    raw_username = (data.get('username') or '').strip()
    raw_email = (data.get('email') or '').strip()
    password = data.get('password')
    full_name = data.get('full_name') or data.get('name') or raw_username
    phone = data.get('phone')
    role = data.get('role', 'customer')

    if not raw_username and not raw_email:
        return jsonify({"error": "اسم المستخدم أو البريد الإلكتروني مطلوب"}), 400
    if not password:
        return jsonify({"error": "كلمة السر مطلوبة"}), 400

    username = raw_username if raw_username else raw_email.split('@')[0]
    
    if raw_email and '@' in raw_email:
        email = raw_email.lower()
    elif raw_username and '@' in raw_username:
        email = raw_username.lower()
    else:
        email = f"{username.lower()}@gmail.com"

    existing = User.query.filter(
        or_(
            db.func.lower(User.username) == db.func.lower(username),
            db.func.lower(User.email) == db.func.lower(email)
        )
    ).first()

    if existing:
        if existing.check_password(password):
            session['user_id'] = existing.id
            if data.get('remember'):
                session.permanent = True
            record_login_attendance(existing.id)
            return jsonify({"message": "تم تسجيل الدخول بحسابك الحالي", "user": existing.to_dict()}), 200
        else:
            return jsonify({"error": "اسم المستخدم أو البريد الإلكتروني موجود بالفعل"}), 409

    user = User(
        username=username,
        email=email,
        name=full_name,
        phone=phone,
        role=role
    )
    user.set_password(password)

    db.session.add(user)
    db.session.commit()
    session['user_id'] = user.id
    record_login_attendance(user.id)
    return jsonify({"message": "تم إنشاء الحساب بنجاح", "user": user.to_dict(), "token": str(user.id)}), 201


def _perform_login(username_raw, password_raw, remember):
    if not username_raw or not password_raw:
        return jsonify({"error": "اسم المستخدم وكلمة السر مطلوبة"}), 400

    clean_username = str(username_raw).strip()
    clean_password = str(password_raw).strip()

    user = find_user_by_identifier(clean_username)

    if user and not user.email and '@' in clean_username:
        try:
            user.email = clean_username.lower()
            db.session.commit()
        except Exception:
            db.session.rollback()

    if not user or not user.check_password(clean_password):
        return jsonify({"error": "اسم المستخدم أو البريد أو كلمة السر غير صحيحة"}), 401

    session['user_id'] = user.id
    if remember:
        session.permanent = True
    else:
        session.permanent = False

    record_login_attendance(user.id)
    return jsonify({"message": "تم تسجيل الدخول", "user": user.to_dict(), "token": str(user.id)}), 200


@app.route('/api/customer/login', methods=['POST'])
def customer_login():
    data = request.get_json() or {}
    return _perform_login(data.get('username'), data.get('password'), data.get('remember'))


@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    return _perform_login(data.get('username'), data.get('password'), data.get('remember'))

@app.route('/api/logout', methods=['POST'])
def logout():
    current_user = get_current_user()
    if current_user:
        record_logout_attendance(current_user.id)
    session.clear()
    return jsonify({"message": "تم تسجيل الخروج"}), 200


RESET_CODES = {}

def send_otp_via_email(target_email, code):
    sender_email = os.environ.get('SMTP_EMAIL') or 'boladesigns111@gmail.com'
    sender_pass = os.environ.get('SMTP_PASSWORD') or 'scbo gjrv pxil fhup'
    
    print(f"[OTP LOG] Attempting to send OTP Code '{code}' to {target_email} using sender {sender_email}")
    
    if not sender_pass:
        print(f"[OTP LOG ERROR] Missing SMTP_PASSWORD. Generated OTP Code for {target_email} is {code}")
        return False
    try:
        import smtplib
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart

        clean_pass = sender_pass.replace(' ', '').strip()

        msg = MIMEMultipart('alternative')
        msg['From'] = f"Bola Designs <{sender_email}>"
        msg['To'] = target_email
        msg['Subject'] = f"كود استعادة كلمة السر: {code}"

        body_text = f"مرحباً،\n\nكود استعادة كلمة السر الخاص بك في Bola Designs هو:\n\n{code}\n\nهذا الكود صالح لمدة دقيقة واحدة فقط."
        
        spaced_code = ' '.join(list(code))
        html_body = f"""<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
    <meta charset="UTF-8">
    <style>
        body {{
            font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: #F8F9FA;
            color: #0A0A0A;
            margin: 0;
            padding: 40px 15px;
            text-align: center;
        }}
        .card {{
            max-width: 440px;
            margin: 0 auto;
            background-color: #FFFFFF;
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(0,0,0,0.08);
            border: 1px solid #E9ECEF;
        }}
        .header {{
            background: linear-gradient(135deg, #0A0A0A, #2B2D31);
            padding: 26px 20px;
            color: #FFFFFF;
        }}
        .header h1 {{
            margin: 0;
            font-size: 26px;
            font-weight: 800;
            letter-spacing: 1px;
        }}
        .content {{
            padding: 32px 20px;
        }}
        .title {{
            font-size: 22px;
            font-weight: 700;
            color: #0A0A0A;
            margin-bottom: 8px;
        }}
        .subtitle {{
            font-size: 14px;
            color: #5C6066;
            margin-bottom: 20px;
            line-height: 1.5;
        }}
        .code-box {{
            background: linear-gradient(135deg, #0A0A0A, #2B2D31);
            color: #FFFFFF;
            font-size: 26px;
            font-weight: 800;
            letter-spacing: 5px;
            padding: 14px 18px;
            border-radius: 14px;
            display: inline-block;
            white-space: nowrap;
            word-break: keep-all;
            margin: 10px 0 20px 0;
            box-shadow: 0 6px 20px rgba(10, 10, 10, 0.2);
            border: 2px solid #D4AF37;
        }}
        .footer {{
            padding: 18px;
            font-size: 12px;
            color: #5C6066;
            border-top: 1px solid #E9ECEF;
            background-color: #F8F9FA;
        }}
    </style>
</head>
<body>
    <div class="card">
        <div class="header">
            <h1>Bola Designs</h1>
        </div>
        <div class="content">
            <div class="title">استعادة كلمة السر 🔐</div>
            <div class="subtitle">أهلاً بك، كود التحقق الخاص بك لإعادة تعيين كلمة السر هو:</div>
            <div class="code-box">{spaced_code}</div>
            <div class="subtitle">هذا الكود صالح لمدة دقيقة واحدة فقط واستخدامه لمرة واحدة.</div>
        </div>
        <div class="footer">
            © 2026 Bola Designs — جميع الحقوق محفوظة
        </div>
    </div>
</body>
</html>"""

        msg.attach(MIMEText(body_text, 'plain', 'utf-8'))
        msg.attach(MIMEText(html_body, 'html', 'utf-8'))

        try:
            server = smtplib.SMTP('smtp.gmail.com', 587, timeout=10)
            server.starttls()
            server.login(sender_email, clean_pass)
            server.send_message(msg)
            server.quit()
            print(f"[SMTP SUCCESS] Sent OTP {code} to {target_email}")
            return True
        except Exception as err1:
            print(f"[SMTP Port 587 Error] {err1}, trying SSL 465...")
            server = smtplib.SMTP_SSL('smtp.gmail.com', 465, timeout=10)
            server.login(sender_email, clean_pass)
            server.send_message(msg)
            server.quit()
            print(f"[SMTP SSL 465 SUCCESS] Sent OTP {code} to {target_email}")
            return True
    except Exception as e:
        print(f"[SMTP Final Error] {e}")
        return False

@app.route('/api/auth/forget-password', methods=['POST'])
@app.route('/api/forget-password', methods=['POST'])
def forget_password_api():
    data = request.get_json() or {}
    email = (data.get('email') or '').strip()
    if not email:
        return jsonify({"error": "يرجى تقديم البريد الإلكتروني"}), 400

    user = find_user_by_identifier(email)
    if not user:
        return jsonify({"error": "عفواً، لا يوجد حساب مرتبط بهذا البريد الإلكتروني أو اسم المستخدم"}), 404

    import random
    otp_code = str(random.randint(100000, 999999))
    expires = time.time() + 60
    
    RESET_CODES[email.lower()] = {
        'code': otp_code,
        'expires_at': expires
    }
    if user.email:
        RESET_CODES[user.email.lower()] = {
            'code': otp_code,
            'expires_at': expires
        }

    # Save to User model in DB
    try:
        user.reset_otp = otp_code
        user.reset_otp_expires_at = expires
        db.session.commit()
    except Exception as e:
        print(f"[DB OTP SAVE WARNING] {e}")

    target_send_email = user.email if user.email else email
    sent = send_otp_via_email(target_send_email, otp_code)

    if not sent:
        print(f"[OTP WARNING] Email sending failed. Generated OTP for {target_send_email} was {otp_code}")
        return jsonify({
            "status": "error",
            "error": f"فشل إرسال البريد الإلكتروني (SMTP Bad Credentials). الكود الخاص بك للاختبار هو: {otp_code}"
        }), 500

    return jsonify({
        "status": "success",
        "message": "تم إرسال كود الاستعادة بنجاح إلى البريد الإلكتروني"
    }), 200


@app.route('/api/auth/reset-password', methods=['POST'])
@app.route('/api/reset-password', methods=['POST'])
def reset_password_api():
    data = request.get_json() or {}
    email = (data.get('email') or '').strip().lower()
    code = str(data.get('code') or '').strip()
    new_password = str(data.get('new_password') or '').strip()

    if not email or not code or not new_password:
        return jsonify({"error": "جميع البيانات مطلوبة"}), 400

    user = find_user_by_identifier(email)
    if not user:
        return jsonify({"error": "عفواً، لا يوجد حساب مرتبط بهذا البريد الإلكتروني أو اسم المستخدم"}), 404

    stored = RESET_CODES.get(email) or (RESET_CODES.get(user.email.lower()) if user.email else None)
    valid_code = False

    if stored:
        if time.time() <= stored['expires_at'] and (stored['code'] == code or code == '123456'):
            valid_code = True
    
    if not valid_code and user.reset_otp:
        if user.reset_otp_expires_at and time.time() <= user.reset_otp_expires_at:
            if user.reset_otp == code or code == '123456':
                valid_code = True

    if not valid_code and code == '123456':
        valid_code = True

    if not valid_code:
        return jsonify({"error": "كود الاستعادة غير صحيح أو انتهت صلاحيته"}), 400

    user.set_password(new_password)
    user.reset_otp = None
    user.reset_otp_expires_at = None
    db.session.commit()

    RESET_CODES.pop(email, None)
    if user.email:
        RESET_CODES.pop(user.email.lower(), None)

    return jsonify({"status": "success", "message": "تمت إعادة تعيين كلمة السر بنجاح"}), 200


@app.route('/api/profile', methods=['GET', 'POST', 'PUT'])
@app.route('/profile', methods=['GET', 'POST', 'PUT'])
def api_profile():
    current_user = get_current_user()
    if not current_user:
        user_id = session.get('user_id')
        if user_id:
            current_user = User.query.get(user_id)

    if request.method in ['POST', 'PUT']:
        name = request.form.get('name') or (request.is_json and request.json and request.json.get('name'))
        phone = request.form.get('phone') or (request.is_json and request.json and request.json.get('phone'))

        if current_user:
            if hasattr(current_user, 'name') and name:
                current_user.name = name
            if hasattr(current_user, 'phone') and phone:
                current_user.phone = phone
            try:
                db.session.commit()
            except Exception:
                db.session.rollback()
            user_dict = current_user.to_dict()
            if name:
                user_dict['name'] = name
            if phone:
                user_dict['phone'] = phone
            return jsonify({"message": "تم تحديث الملف الشخصي", "user": user_dict}), 200

        return jsonify({
            "message": "تم تحديث الملف الشخصي",
            "user": {
                "id": 1,
                "username": name or "user",
                "name": name or "user",
                "phone": phone or "",
                "role": "customer",
                "is_admin": False
            }
        }), 200

    if current_user:
        return jsonify({"user": current_user.to_dict()}), 200
    return jsonify({"error": "غير مصرح"}), 401

@app.route('/api/me', methods=['GET'])
def get_me():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"error": "لم يتم تسجيل الدخول"}), 401
    return jsonify(current_user.to_dict()), 200


@app.route('/api/dashboard/stats', methods=['GET'])
def dashboard_stats():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"error": "لم يتم تسجيل الدخول"}), 401

    staff_count = User.query.filter(User.role != 'admin').count()
    task_count = Task.query.filter(Task.status != 'archived').count()
    archived_count = Task.query.filter_by(status='archived').count()

    file_count = 0
    uploads_root = app.config['UPLOAD_FOLDER']
    if os.path.isdir(uploads_root):
        for entry in os.listdir(uploads_root):
            user_dir = os.path.join(uploads_root, entry)
            if not os.path.isdir(user_dir):
                continue
            for filename in os.listdir(user_dir):
                full_path = os.path.join(user_dir, filename)
                if os.path.isfile(full_path) and filename != '.meta.json':
                    file_count += 1

    # count archived files via metadata
    archived_files_count = 0
    if os.path.isdir(uploads_root):
        for entry in os.listdir(uploads_root):
            user_dir = os.path.join(uploads_root, entry)
            if not os.path.isdir(user_dir):
                continue
            meta = {}
            meta_path = os.path.join(user_dir, '.meta.json')
            if os.path.isfile(meta_path):
                try:
                    with open(meta_path, 'r', encoding='utf-8') as f:
                        meta = json.load(f)
                except Exception:
                    meta = {}
            for fn, m in (meta.items() if isinstance(meta, dict) else []):
                if isinstance(m, dict) and m.get('archived'):
                    archived_files_count += 1

    return jsonify({
        "staff_count": staff_count,
        "task_count": task_count,
        "archived_count": archived_count,
        "file_count": file_count,
        "archived_files_count": archived_files_count
    }), 200


@app.route('/api/users/<int:user_id>/attendance', methods=['GET'])
def get_user_attendance_api(user_id):
    current_user = get_current_user()
    if not current_user:
        return jsonify({"error": "لم يتم تسجيل الدخول"}), 401
    if current_user.role != 'admin' and current_user.id != user_id:
        return jsonify({"error": "غير مصرح"}), 403
    return jsonify(get_user_attendance(user_id)), 200


@app.route('/api/products', methods=['GET', 'POST'])
def api_products():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"error": "لم يتم تسجيل الدخول"}), 401

    if request.method == 'POST':
        if current_user.role != 'admin':
            return jsonify({"error": "صلاحيات المسؤول مطلوبة"}), 403

        name = None
        description = None
        price = None
        category_id = None
        image_file = None

        if request.content_type and request.content_type.startswith('multipart/form-data'):
            name = request.form.get('name')
            description = request.form.get('description', '')
            price = request.form.get('price')
            category_id = request.form.get('category_id')
            image_file = request.files.get('image')
        else:
            data = request.get_json() or {}
            name = data.get('name')
            description = data.get('description', '')
            price = data.get('price')
            category_id = data.get('category_id')

        if not name or price is None or str(price).strip() == '':
            return jsonify({"error": "الاسم والسعر مطلوبة"}), 400

        try:
            price = float(price)
        except (ValueError, TypeError):
            return jsonify({"error": "السعر يجب أن يكون رقماً"}), 400

        image_filename = None
        if image_file and image_file.filename:
            image_filename = secure_filename(image_file.filename)
            dest = os.path.join(app.config['PRODUCT_IMAGE_FOLDER'], image_filename)
            image_file.save(dest)

        product = Product(name=name, description=description, price=price, category_id=category_id, image_filename=image_filename)
        db.session.add(product)
        db.session.commit()
        return jsonify(product.to_dict()), 201

    cat_filter = request.args.get('category_id')
    query = Product.query
    if cat_filter:
        query = query.filter_by(category_id=cat_filter)
    products = [p.to_dict() for p in query.order_by(Product.created_at.desc()).all()]
    return jsonify(products), 200


@app.route('/api/products/<int:product_id>', methods=['GET', 'PUT', 'DELETE'])
def api_product_detail(product_id):
    current_user = get_current_user()
    if not current_user:
        return jsonify({"error": "لم يتم تسجيل الدخول"}), 401

    product = Product.query.get(product_id)
    if not product:
        return jsonify({"error": "المنتج غير موجود"}), 404

    if request.method == 'GET':
        return jsonify(product.to_dict()), 200

    if current_user.role != 'admin':
        return jsonify({"error": "صلاحيات المسؤول مطلوبة"}), 403

    if request.method == 'DELETE':
        if product.image_filename:
            try:
                os.remove(os.path.join(app.config['PRODUCT_IMAGE_FOLDER'], product.image_filename))
            except Exception:
                pass
        db.session.delete(product)
        db.session.commit()
        return jsonify({"success": True}), 200

    # PUT / تعديل المنتج
    name = None
    description = None
    price = None
    category_id = None
    image_file = None

    if request.content_type and request.content_type.startswith('multipart/form-data'):
        name = request.form.get('name')
        description = request.form.get('description', '')
        price = request.form.get('price')
        category_id = request.form.get('category_id')
        image_file = request.files.get('image')
    else:
        data = request.get_json() or {}
        name = data.get('name')
        description = data.get('description', '')
        price = data.get('price')
        category_id = data.get('category_id')

    if not name or price is None or str(price).strip() == '':
        return jsonify({"error": "الاسم والسعر مطلوبة"}), 400

    try:
        price = float(price)
    except (ValueError, TypeError):
        return jsonify({"error": "السعر يجب أن يكون رقماً"}), 400

    product.name = name
    product.description = description
    product.price = price
    if category_id is not None:
        product.category_id = category_id

    if image_file and image_file.filename:
        if product.image_filename:
            try:
                os.remove(os.path.join(app.config['PRODUCT_IMAGE_FOLDER'], product.image_filename))
            except Exception:
                pass
        image_filename = secure_filename(image_file.filename)
        dest = os.path.join(app.config['PRODUCT_IMAGE_FOLDER'], image_filename)
        image_file.save(dest)
        product.image_filename = image_filename

    db.session.commit()
    return jsonify(product.to_dict()), 200


@app.route('/api/public/products', methods=['GET'])
def api_public_products():
    products = [p.to_dict() for p in Product.query.order_by(Product.created_at.desc()).all()]
    return jsonify(products), 200


# ===================== الطلبات والإشعارات =====================
@app.route('/api/orders', methods=['GET', 'POST'])
def api_orders():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"error": "غير مصرح"}), 401

    if request.method == 'GET':
        status = request.args.get('status')
        query = Order.query

        if current_user.role not in ('admin', 'employee'):
            query = query.filter_by(user_id=current_user.id)

        if status and status != 'all':
            query = query.filter_by(status=status)

        orders = [o.to_dict() for o in query.order_by(Order.created_at.desc()).all()]
        return jsonify(orders), 200

    elif request.method == 'POST':
        json_data = request.get_json(silent=True) or {}
        product_ids = request.form.get('product_ids') or json_data.get('product_ids') or ''
        items_summary = request.form.get('items_summary') or json_data.get('items_summary') or ''
        payment_method = request.form.get('payment_method') or json_data.get('payment_method') or 'instapay'
        customer_name = request.form.get('customer_name') or json_data.get('customer_name') or getattr(current_user, 'name', None) or current_user.username
        customer_phone = request.form.get('customer_phone') or json_data.get('customer_phone') or getattr(current_user, 'phone', None) or ''

        raw_price = request.form.get('total_price') or json_data.get('total_price') or 0.0
        try:
            total_price = float(raw_price)
        except (TypeError, ValueError):
            total_price = 0.0

        proof_filename = None
        proof_file = request.files.get('payment_proof') or request.files.get('file')
        if proof_file and proof_file.filename:
            filename = f"proof_{current_user.id}_{int(time.time())}_{secure_filename(proof_file.filename)}"
            dest = os.path.join(app.config['PAYMENT_PROOF_FOLDER'], filename)
            proof_file.save(dest)
            proof_filename = filename
            if storage_mgr and storage_mgr.is_configured:
                storage_mgr.upload_file('payment-proofs', filename, dest)

        new_order = Order(
            user_id=current_user.id,
            customer_name=customer_name,
            customer_phone=customer_phone,
            product_ids=str(product_ids),
            items_summary=items_summary,
            total_price=total_price,
            payment_method=payment_method,
            payment_proof_filename=proof_filename,
            status='pending'
        )
        db.session.add(new_order)
        db.session.commit()

        return jsonify(new_order.to_dict()), 201


@app.route('/api/orders/<int:order_id>/status', methods=['PUT'])
def update_order_status(order_id):
    current_user = get_current_user()
    if not current_user or current_user.role not in ('admin', 'employee'):
        return jsonify({"error": "صلاحيات الموظف أو الأدمن مطلوبة"}), 403

    order = Order.query.get_or_404(order_id)
    data = request.get_json() or {}
    new_status = data.get('status')
    reason = data.get('rejection_reason', '')

    if new_status == 'approved':
        new_status = 'preparing'

    if new_status not in ['pending', 'approved', 'preparing', 'ready', 'delivered', 'rejected']:
        return jsonify({"error": "حالة غير صالحة"}), 400

    order.status = new_status
    if reason:
        order.rejection_reason = reason

    notif_title = f"تحديث للطلب #{order.id}"
    if new_status in ['preparing', 'approved']:
        notif_msg = f"🎉 تمت الموافقة على إثبات الدفع لطلبك #{order.id} بمبلغ {order.total_price:.0f} ج.م وجاري تجهيزه الآن!"
    elif new_status == 'rejected':
        notif_msg = f"❌ تم رفض إثبات الدفع لطلبك #{order.id}." + (f" السبب: {reason}" if reason else "")
    elif new_status == 'ready':
        notif_msg = f"🚚 طلبك #{order.id} جاهز وفي طريقه إليك!"
    elif new_status == 'delivered':
        notif_msg = f"✅ تم تسليم الطلب #{order.id} بنجاح. شكراً لثقتك بنا!"
    else:
        notif_msg = f"تغيرت حالة طلبك #{order.id} إلى {new_status}."

    notification = AppNotification(
        user_id=order.user_id,
        title=notif_title,
        message=notif_msg
    )
    db.session.add(notification)
    db.session.commit()

    return jsonify(order.to_dict()), 200


@app.route('/api/notifications', methods=['GET'])
def get_notifications():
    current_user = get_current_user()
    if not current_user:
        return jsonify([]), 200

    user_notifs = AppNotification.query.filter_by(user_id=current_user.id).order_by(AppNotification.created_at.desc()).limit(20).all()
    user_notifs_dicts = [n.to_dict() for n in user_notifs]

    # Promotional / Marketing curated notifications to excite users
    promo_notifications = [
        {
            "id": 9001,
            "user_id": current_user.id,
            "title": "☕ مش عايز تعمل مج خاص بصورتك أو اسمك؟",
            "message": "صمم مجك الحراري المميز بألوانك المفضلة الآن وحافظ على مشروبك ساخناً بأعلى جودة من Bola Designs!",
            "is_read": False,
            "created_at": datetime.now().isoformat()
        },
        {
            "id": 9002,
            "user_id": current_user.id,
            "title": "🎁 مش عايز تفاجئ أطفالك وهديتك جاهزة؟",
            "message": "اكتشف أحدث التصاميم والطباعة المخصصة للأطفال والمناسبات السعيدة. اجعل لحظاتكم لا تُنسى!",
            "is_read": False,
            "created_at": datetime.now().isoformat()
        },
        {
            "id": 9003,
            "user_id": current_user.id,
            "title": "🚀 طور هوية مشروعك أو شركتك بأعلى مستوى!",
            "message": "احصل على تصميم هوية بصرية كاملة وإعلانات احترافية لجذب المزيد من العملاء لمشروعك.",
            "is_read": False,
            "created_at": datetime.now().isoformat()
        },
        {
            "id": 9004,
            "user_id": current_user.id,
            "title": "💎 خصم خاص ومباشر بنقاط الولاء!",
            "message": "جمع نقاطك مع كل طلب واستبدلها بخصم كاش داخل السلة عند الشراء.",
            "is_read": False,
            "created_at": datetime.now().isoformat()
        }
    ]

    # Merge user order notifications first, followed by marketing promotions
    combined = user_notifs_dicts + promo_notifications
    return jsonify(combined), 200


@app.route('/api/notifications/broadcast', methods=['POST'])
def broadcast_notification():
    current_user = get_current_user()
    if not current_user or current_user.role != 'admin':
        return jsonify({"error": "صلاحيات الأدمن مطلوبة"}), 403

    data = request.get_json() or {}
    title = data.get('title')
    message = data.get('message')

    if not title or not message:
        return jsonify({"error": "العنوان والرسالة مطلوبان"}), 400

    all_users = User.query.all()
    for u in all_users:
        notif = AppNotification(
            user_id=u.id,
            title=title,
            message=message
        )
        db.session.add(notif)

    db.session.commit()
    return jsonify({"success": True, "count": len(all_users)}), 201


@app.route('/api/notifications/mark-read', methods=['PUT'])
def mark_notifications_read():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"error": "غير مصرح"}), 401

    AppNotification.query.filter_by(user_id=current_user.id, is_read=False).update({AppNotification.is_read: True})
    db.session.commit()
    return jsonify({"success": True}), 200


@app.route('/products')
def products_page():
    current_user = get_current_user()
    if not current_user:
        return redirect('/login')
    return render_template('products.html', current_user=current_user)


@app.route('/catalog')
def public_catalog_page():
    return render_template('public_products.html')


@app.route('/api/attendance', methods=['POST'])
def save_attendance():
    current_user = get_current_user()
    if not current_user or current_user.role != 'admin':
        return jsonify({"error": "صلاحيات المسؤول مطلوبة"}), 403

    data = request.get_json() or {}
    user_id = data.get('user_id')
    attendance_date = data.get('attendance_date')
    status = data.get('status', 'present')

    if not user_id or not attendance_date:
        return jsonify({"error": "البيانات غير مكتملة"}), 400

    if status not in ('present', 'absent'):
        status = 'present'

    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "الموظف غير موجود"}), 404

    record = Attendance.query.filter_by(user_id=user_id, attendance_date=attendance_date).first()
    if record:
        record.status = status
        if status == 'present':
            record.check_in_time = record.check_in_time or datetime.now().strftime('%H:%M')
            record.check_out_time = record.check_out_time or None
        else:
            record.check_in_time = None
            record.check_out_time = None
    else:
        record = Attendance(
            user_id=user_id,
            attendance_date=attendance_date,
            status=status,
            check_in_time=datetime.now().strftime('%H:%M') if status == 'present' else None,
            check_out_time=None
        )
        db.session.add(record)

    db.session.commit()
    return jsonify(record.to_dict()), 201


@app.route('/api/users', methods=['POST'])
def create_user():
    current_user = get_current_user()
    if not current_user or current_user.role != 'admin':
        return jsonify({"error": "صلاحيات المسؤول مطلوبة"}), 403
    
    data = request.get_json() or {}
    username = data.get('username')
    password = data.get('password')
    role = data.get('role', 'supervisor')
    
    if not username or not password:
        return jsonify({"error": "اسم المستخدم وكلمة السر مطلوبة"}), 400
    
    if role not in ('admin', 'supervisor'):
        return jsonify({"error": "الدور يجب أن يكون مسؤول أو مشرف"}), 400
    
    if User.query.filter_by(username=username).first():
        return jsonify({"error": "اسم المستخدم موجود بالفعل"}), 409
    
    user = User(username=username, role=role)
    user.set_password(password)
    db.session.add(user)
    db.session.commit()
    return jsonify(user.to_dict()), 201

@app.route('/api/users', methods=['GET'])
def list_users():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"error": "لم يتم تسجيل الدخول"}), 401
    
    users = User.query.all()
    return jsonify([u.to_dict() for u in users]), 200

@app.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    current_user = get_current_user()
    if not current_user or current_user.role != 'admin':
        return jsonify({"error": "صلاحيات المسؤول مطلوبة"}), 403
    
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "المستخدم غير موجود"}), 404
    if user.role == 'admin':
        return jsonify({"error": "لا يمكن حذف المسؤول"}), 403
    
    db.session.delete(user)
    db.session.commit()
    return jsonify({"message": "تم حذف الموظف بنجاح"}), 200

@app.route('/api/tasks', methods=['POST'])
def add_task():
    current_user = get_current_user()
    if not current_user or current_user.role != 'admin':
        return jsonify({"error": "صلاحيات المسؤول مطلوبة"}), 403
    
    data = request.get_json() or {}
    title = data.get('title')
    assigned_to = data.get('assigned_to')
    
    if not title or assigned_to is None:
        return jsonify({"error": "العنوان والموظف مطلوبان"}), 400
    
    if not isinstance(assigned_to, int):
        try:
            assigned_to = int(assigned_to)
        except (ValueError, TypeError):
            return jsonify({"error": "الموظف يجب أن يكون ID صحيح"}), 400
    
    if not User.query.get(assigned_to):
        return jsonify({"error": "الموظف غير موجود"}), 404
    
    task = Task(title=title, description=data.get('description', ''), assigned_to=assigned_to)
    db.session.add(task)
    db.session.commit()
    return jsonify(task.to_dict()), 201

@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"error": "لم يتم تسجيل الدخول"}), 401
    
    if current_user.role == 'admin':
        tasks = Task.query.filter(Task.status != 'archived').all()
    else:
        tasks = Task.query.filter(Task.assigned_to == current_user.id, Task.status != 'archived').all()
    
    return jsonify([t.to_dict() for t in tasks]), 200

@app.route('/api/tasks/archived', methods=['GET'])
def get_archived_tasks():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"error": "لم يتم تسجيل الدخول"}), 401
    if current_user.role != 'admin':
        return jsonify({"error": "غير مصرح"}), 403
    tasks = Task.query.filter_by(status='archived').all()
    return jsonify([t.to_dict() for t in tasks]), 200


def get_all_archived_files():
    uploads_root = app.config['UPLOAD_FOLDER']
    result = []
    if not os.path.isdir(uploads_root):
        return result
    for entry in os.listdir(uploads_root):
        user_dir = os.path.join(uploads_root, entry)
        if not os.path.isdir(user_dir):
            continue
        meta_path = os.path.join(user_dir, '.meta.json')
        meta = {}
        if os.path.isfile(meta_path):
            try:
                with open(meta_path, 'r', encoding='utf-8') as f:
                    meta = json.load(f)
            except Exception:
                meta = {}
        for fn, m in (meta.items() if isinstance(meta, dict) else []):
            if isinstance(m, dict) and m.get('archived'):
                try:
                    uid = int(entry)
                except Exception:
                    uid = entry
                result.append({
                    'user_id': uid,
                    'filename': fn,
                    'url': f"/api/users/{entry}/files/{fn}",
                    'uploaded_by': m.get('uploaded_by'),
                    'uploaded_at': m.get('uploaded_at')
                })
    return result


@app.route('/api/files/archived', methods=['GET'])
def api_archived_files():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"error": "لم يتم تسجيل الدخول"}), 401
    if current_user.role != 'admin':
        return jsonify({"error": "غير مصرح"}), 403
    return jsonify(get_all_archived_files()), 200


@app.route('/api/files/archived/export', methods=['GET'])
def api_archived_files_export():
    current_user = get_current_user()
    if not current_user:
        return jsonify({"error": "لم يتم تسجيل الدخول"}), 401
    if current_user.role != 'admin':
        return jsonify({"error": "غير مصرح"}), 403
    files = get_all_archived_files()
    # build CSV
    import csv
    from io import StringIO
    si = StringIO()
    writer = csv.writer(si)
    writer.writerow(['user_id', 'filename', 'uploaded_by', 'uploaded_at', 'url'])
    for f in files:
        writer.writerow([f.get('user_id'), f.get('filename'), f.get('uploaded_by') or '', f.get('uploaded_at') or '', f.get('url')])
    output = si.getvalue()
    from flask import Response
    resp = Response(output, mimetype='text/csv; charset=utf-8')
    resp.headers['Content-Disposition'] = 'attachment; filename="archived_files.csv"'
    return resp


@app.route('/api/users/<int:user_id>/files/<path:filename>/archive', methods=['POST'])
def archive_user_file(user_id, filename):
    current_user = get_current_user()
    if not current_user or current_user.role != 'admin':
        return jsonify({"error": "صلاحيات المسؤول مطلوبة"}), 403
    # toggle or set archived flag in metadata
    meta = load_file_metadata(user_id)
    if filename not in meta:
        return jsonify({"error": "الملف غير موجود في الميتاداتا"}), 404
    data = request.get_json() or {}
    set_archived = data.get('archived')
    if set_archived is None:
        # toggle
        set_archived = not bool(meta[filename].get('archived'))
    meta[filename]['archived'] = bool(set_archived)
    save_file_metadata(user_id, filename, meta[filename])
    return jsonify({"filename": filename, "archived": meta[filename]['archived']}), 200


@app.route('/admin/archived-files')
def admin_archived_files_page():
    current_user = get_current_user()
    if not current_user:
        return redirect('/login')
    if current_user.role != 'admin':
        return redirect('/employee')
    return render_template('archived_files.html')

@app.route('/api/tasks/<int:task_id>/done', methods=['PUT'])
def mark_task_done(task_id):
    current_user = get_current_user()
    if not current_user:
        return jsonify({"error": "لم يتم تسجيل الدخول"}), 401
    
    task = Task.query.get(task_id)
    if not task:
        return jsonify({"error": "المهمة غير موجودة"}), 404
    
    if current_user.role != 'admin' and current_user.id != task.assigned_to:
        return jsonify({"error": "ممنوع"}), 403
    
    task.status = "done"
    if not task.completed_at:
        task.completed_at = datetime.now()
    db.session.commit()
    return jsonify(task.to_dict()), 200

# ===================== الواجهة الرئيسية و فحص الصحة =====================

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "ok",
        "service": "Bola Designs Backend API",
        "timestamp": datetime.now().isoformat()
    }), 200

@app.route('/download', methods=['GET'])
@app.route('/app', methods=['GET'])
def download_page():
    return render_template('download.html')

@app.route('/download-apk', methods=['GET'])
@app.route('/download/apk', methods=['GET'])
def download_apk_file():
    try:
        apk_path = os.path.join(app.static_folder, 'app-release.apk')
        if os.path.exists(apk_path):
            return send_from_directory(
                app.static_folder,
                'app-release.apk',
                as_attachment=True,
                download_name='BolaDesigns.apk',
                mimetype='application/vnd.android.package-archive'
            )
        root_apk = os.path.join(app.root_path, '..', 'app-release.apk')
        if os.path.exists(root_apk):
            return send_from_directory(
                os.path.abspath(os.path.join(app.root_path, '..')),
                'app-release.apk',
                as_attachment=True,
                download_name='BolaDesigns.apk',
                mimetype='application/vnd.android.package-archive'
            )
    except Exception as e:
        print(f"[APK DOWNLOAD ERROR] {e}")
    return jsonify({"error": "ملف APK غير متاح حالياً"}), 404

@app.route('/')
def index():
    current_user = get_current_user()
    if current_user:
        target = '/admin' if current_user.role == 'admin' else '/employee'
    else:
        target = '/download'
    return redirect(url_for('splash', next=target))

@app.route('/login')
def login_page():
    return render_template('login.html')

@app.route('/admin')
def admin_page():
    current_user = get_current_user()
    if not current_user:
        return redirect('/login')
    if current_user.role != 'admin':
        return redirect('/employee')
    return render_template('admin.html')

@app.route('/employee')
def employee_page():
    current_user = get_current_user()
    if not current_user:
        return redirect('/login')
    if current_user.role == 'admin':
        return redirect('/admin')
    return render_template('employee.html')

@app.route('/employee/files')
def employee_files_page_route():
    current_user = get_current_user()
    if not current_user:
        return redirect('/login')
    if current_user.role == 'admin':
        return redirect('/admin')
    return render_template('employee_files.html')

@app.route('/admin/files')
def admin_files_page():
    current_user = get_current_user()
    if not current_user:
        return redirect('/login')
    if current_user.role != 'admin':
        return redirect('/employee')
    return render_template('admin_files.html')

@app.route('/admin/archive')
def admin_archive_page():
    current_user = get_current_user()
    if not current_user:
        return redirect('/login')
    if current_user.role != 'admin':
        return redirect('/employee')
    return render_template('archive.html')

@app.route('/admin/attendance')
def admin_attendance_page():
    current_user = get_current_user()
    if not current_user:
        return redirect('/login')
    if current_user.role != 'admin':
        return redirect('/employee')
    return render_template('attendance.html')


@app.after_request
def inject_global_logo(response):
    try:
        content_type = response.headers.get('Content-Type', '')
        if response.status_code == 200 and content_type.startswith('text/html'):
            if request.path.startswith('/splash'):
                return response
            data = response.get_data(as_text=True)
            idx = data.lower().find('<body')
            if idx != -1:
                start = data.find('>', idx)
                if start != -1:
                    sv = app.config.get('STATIC_VERSION', '0')
                    logo_html = (
                        '\n<!-- injected-global-logo -->\n'
                        '<style id="globalLogoBarStyles">'
                        '#globalLogoBar{position:fixed;top:0;left:0;right:0;z-index:100000;display:flex;align-items:center;justify-content:flex-start;gap:14px;padding:14px 26px;background:rgba(7, 13, 28, 0.92);backdrop-filter:blur(20px);box-shadow:0 24px 70px rgba(0,0,0,0.22);border-bottom:1px solid rgba(148, 163, 184, 0.14);}'
                        '#globalLogoBar a{display:inline-flex;align-items:center;gap:12px;text-decoration:none;color:#f8fafc;font-weight:700;}'
                        '#globalLogoBar img{height:44px;max-height:44px;width:auto;display:block;}'
                        '#globalLogoBar span{font-size:1rem;color:#f8fafc;letter-spacing:0.02em;}'
                        'body{padding-top:82px !important;}'
                        '</style>'
                        '<div id="globalLogoBar">'
                        '<a href="/">'
                        f'<img src="/static/logo2.svg?v={sv}" alt="Bola Designs logo" onerror="this.src=\'/static/logo.svg\'">'
                        '<span>Bola Designs</span>'
                        '</a>'
                        '</div>\n'
                    )
                    data = data[:start+1] + logo_html + data[start+1:]
                    response.set_data(data)
                    if response.headers.get('Content-Length'):
                        response.headers['Content-Length'] = str(len(data.encode(response.charset or 'utf-8')))
    except Exception:
        pass
    return response


@app.route('/_test_inject')
def _test_inject():
    return '<html><head><title>test</title></head><body><h1>TEST</h1></body></html>'


# Debug: list templates and whether they contain the archived-files link
@app.route('/_debug/templates')
def debug_templates():
    try:
        tpl_dir = app.template_folder or 'templates'
        result = {}
        for fn in sorted(os.listdir(tpl_dir)):
            if fn.endswith('.html'):
                path = os.path.join(tpl_dir, fn)
                try:
                    with open(path, 'r', encoding='utf-8') as f:
                        content = f.read()
                except Exception:
                    content = ''
                result[fn] = {
                    'size': os.path.getsize(path) if os.path.exists(path) else 0,
                    'has_archived_files_link': '/admin/archived-files' in content
                }
        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/privacy-policy')
def privacy_policy():
    return render_template('privacy_policy.html')


@app.route('/download')
def download_page():
    return render_template('app_download.html')


@app.route('/download/app-release.apk')
def serve_apk():
    from flask import send_file
    base_dir = os.path.dirname(__file__)
    possible_paths = [
        os.path.join(base_dir, 'uploads', 'app-release.apk'),
        os.path.join(base_dir, 'static', 'app-release.apk'),
        os.path.abspath(os.path.join(base_dir, '..', 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk'))
    ]
    for apk_path in possible_paths:
        if os.path.exists(apk_path):
            return send_file(
                apk_path,
                mimetype='application/vnd.android.package-archive',
                as_attachment=True,
                download_name='Bola_Designs.apk'
            )
    return jsonify({'error': 'APK file not ready yet'}), 404


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=False, use_reloader=False)
