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
CORS(app, supports_credentials=True)

# قاعدة البيانات: القراءة من DATABASE_URL أولاً (سواء Supabase Postgres أو غيره) مع fallback لـ SQLite المحلي
DATABASE_URL = os.environ.get('DATABASE_URL')
if DATABASE_URL:
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)
    app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
else:
    db_path = os.path.join(os.path.dirname(__file__), 'tasks.db')
    app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'

app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY') or secrets.token_hex(32)
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(days=30)
app.config['STATIC_VERSION'] = str(int(time.time()))
# reduce static file caching during development
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0
db = SQLAlchemy(app)

# expose STATIC_VERSION to templates
app.jinja_env.globals['STATIC_VERSION'] = app.config['STATIC_VERSION']

# uploads configuration
app.config['UPLOAD_FOLDER'] = os.path.join(os.path.dirname(__file__), 'uploads')
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
app.config['PRODUCT_IMAGE_FOLDER'] = os.path.join(app.static_folder, 'product_images')
os.makedirs(app.config['PRODUCT_IMAGE_FOLDER'], exist_ok=True)


# ===================== المودلات =====================
class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), nullable=False)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            "id": self.id,
            "username": self.username,
            "name": getattr(self, 'name', self.username),
            "phone": getattr(self, 'phone', ''),
            "role": self.role,
            "is_admin": self.role == 'admin'
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


def ensure_product_columns():
    try:
        with db.engine.connect() as conn:
            columns = [c['name'] for c in inspect(db.engine).get_columns('products')]
            if 'image_filename' not in columns:
                conn.execute(text("ALTER TABLE products ADD COLUMN image_filename VARCHAR(255)"))
                conn.commit()
    except Exception:
        pass

# ===================== إنشاء قاعدة البيانات =====================
with app.app_context():
    db.create_all()
    ensure_attendance_columns()
    ensure_task_columns()
    ensure_product_columns()
    if User.query.count() == 0:
        admin = User(username='admin', role='admin')
        admin.set_password('admin123')
        db.session.add(admin)
        db.session.commit()
    if not User.query.filter_by(username='Bola').first():
        bola = User(username='Bola', role='admin')
        bola.set_password('78945612300')
        db.session.add(bola)
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
        return User.query.get(session['user_id'])
    return None


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
    user_dir = os.path.join(app.config['UPLOAD_FOLDER'], str(user_id))
    meta = load_file_metadata(user_id)
    files = []
    
    filenames = set(meta.keys())
    if os.path.isdir(user_dir):
        for fn in os.listdir(user_dir):
            if fn != '.meta.json' and os.path.isfile(os.path.join(user_dir, fn)):
                filenames.add(fn)

    for fn in sorted(filenames):
        item_meta = meta.get(fn, {})
        file_url = item_meta.get('storage_url') or f"/api/users/{user_id}/files/{fn}"
        files.append({
            "filename": fn,
            "url": file_url,
            "uploaded_by": item_meta.get('uploaded_by', 'غير معروف'),
            "uploaded_by_id": item_meta.get('uploaded_by_id'),
            "uploaded_by_role": item_meta.get('uploaded_by_role'),
            "uploaded_at": item_meta.get('uploaded_at')
        })
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


# ===================== رفع ملفات الموظفين =====================
def user_allowed(current_user, target_user_id):
    if not current_user:
        return False
    if current_user.role == 'admin':
        return True
    return current_user.id == target_user_id


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

    filename = secure_filename(file.filename)
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
        "uploaded_at": datetime.now().isoformat()
    }
    if storage_url:
        meta_data["storage_url"] = storage_url

    save_file_metadata(user_id, filename, meta_data)
    res_url = storage_url or f"/api/users/{user_id}/files/{filename}"
    return jsonify({"message": "تم رفع الملف", "filename": filename, "url": res_url}), 201


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


# ===================== المسارات =====================
@app.route('/api/customer/register', methods=['POST'])
@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json() or {}
    username = data.get('username') or data.get('email')
    password = data.get('password')
    full_name = data.get('full_name') or data.get('name')
    email = data.get('email')
    phone = data.get('phone')
    role = data.get('role', 'customer')

    if not username or not password:
        return jsonify({"error": "اسم المستخدم وكلمة السر مطلوبة"}), 400

    username = str(username).strip()
    existing = User.query.filter(
        or_(
            db.func.lower(User.username) == db.func.lower(username),
            db.func.lower(User.username) == db.func.lower(email.strip() if email else username)
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

    user = User(username=username, role=role)
    user.set_password(password)

    db.session.add(user)
    db.session.commit()
    session['user_id'] = user.id
    record_login_attendance(user.id)
    return jsonify({"message": "تم إنشاء الحساب بنجاح", "user": user.to_dict()}), 201


@app.route('/api/customer/login', methods=['POST'])
def customer_login():
    data = request.get_json() or {}
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({"error": "اسم المستخدم وكلمة السر مطلوبة"}), 400

    username = str(username).strip()
    user = User.query.filter(db.func.lower(User.username) == db.func.lower(username)).first()
    if not user or not user.check_password(password):
        return jsonify({"error": "بيانات الدخول غير صحيحة"}), 401

    session['user_id'] = user.id
    if data.get('remember'):
        session.permanent = True
    else:
        session.permanent = False
    record_login_attendance(user.id)
    return jsonify({"message": "تم تسجيل الدخول", "user": user.to_dict()}), 200


@app.route('/api/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    username = data.get('username')
    password = data.get('password')
    
    if not username or not password:
        return jsonify({"error": "اسم المستخدم وكلمة السر مطلوبة"}), 400
    
    user = User.query.filter(db.func.lower(User.username) == db.func.lower(username.strip())).first()
    if not user or not user.check_password(password):
        return jsonify({"error": "بيانات الدخول غير صحيحة"}), 401
    
    session['user_id'] = user.id
    if data.get('remember'):
        session.permanent = True
    else:
        session.permanent = False
    record_login_attendance(user.id)
    return jsonify({"message": "تم تسجيل الدخول", "user": user.to_dict()}), 200

@app.route('/api/logout', methods=['POST'])
def logout():
    current_user = get_current_user()
    if current_user:
        record_logout_attendance(current_user.id)
    session.clear()
    return jsonify({"message": "تم تسجيل الخروج"}), 200


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
        image_file = None

        if request.content_type and request.content_type.startswith('multipart/form-data'):
            name = request.form.get('name')
            description = request.form.get('description', '')
            price = request.form.get('price')
            image_file = request.files.get('image')
        else:
            data = request.get_json() or {}
            name = data.get('name')
            description = data.get('description', '')
            price = data.get('price')

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

        product = Product(name=name, description=description, price=price, image_filename=image_filename)
        db.session.add(product)
        db.session.commit()
        return jsonify(product.to_dict()), 201

    products = [p.to_dict() for p in Product.query.order_by(Product.created_at.desc()).all()]
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
    image_file = None

    if request.content_type and request.content_type.startswith('multipart/form-data'):
        name = request.form.get('name')
        description = request.form.get('description', '')
        price = request.form.get('price')
        image_file = request.files.get('image')
    else:
        data = request.get_json() or {}
        name = data.get('name')
        description = data.get('description', '')
        price = data.get('price')

    if not name or price is None or str(price).strip() == '':
        return jsonify({"error": "الاسم والسعر مطلوبة"}), 400

    try:
        price = float(price)
    except (ValueError, TypeError):
        return jsonify({"error": "السعر يجب أن يكون رقماً"}), 400

    product.name = name
    product.description = description
    product.price = price

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

# ===================== الواجهة الرئيسية =====================

@app.route('/')
def index():
    current_user = get_current_user()
    if current_user:
        target = '/admin' if current_user.role == 'admin' else '/employee'
    else:
        target = '/login'
    # show a splash screen first, then redirect to the intended target
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


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=False, use_reloader=False)
