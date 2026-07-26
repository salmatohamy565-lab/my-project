import os
import sys
import sqlite3
import json

# إضافة مسار المجلد الحالي
sys.path.insert(0, os.path.dirname(__file__))

def run_migration():
    print("=" * 60)
    print("=== [START] Migrating App Data to Supabase (Database & Storage) ===")
    print("=" * 60)

    try:
        from dotenv import load_dotenv
        env_path = os.path.join(os.path.dirname(__file__), '.env')
        load_dotenv(dotenv_path=env_path)
    except ImportError:
        pass

    env_path = os.path.join(os.path.dirname(__file__), '.env')
    if os.path.isfile(env_path):
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    k, v = line.split('=', 1)
                    os.environ[k.strip()] = v.strip()

    target_db_url = os.environ.get('DATABASE_URL')
    if not target_db_url:
        print("[ERROR] DATABASE_URL not found in environment!")
        return

    if target_db_url.startswith("postgres://"):
        target_db_url = target_db_url.replace("postgres://", "postgresql://", 1)

    # 1. الاتصال بـ SQLite المحلي لقراءة البيانات الحالية
    sqlite_db_path = os.path.join(os.path.dirname(__file__), 'tasks.db')
    if not os.path.isfile(sqlite_db_path):
        print(f"[INFO] SQLite database {sqlite_db_path} not found.")
        has_sqlite = False
    else:
        has_sqlite = True
        sqlite_conn = sqlite3.connect(sqlite_db_path)
        sqlite_conn.row_factory = sqlite3.Row
        sqlite_cursor = sqlite_conn.cursor()

    # 2. تهيئة الاتصال بـ Postgres عبر SQLAlchemy
    print("\n[1/3] Creating tables on Supabase PostgreSQL...")
    os.environ['DATABASE_URL'] = target_db_url
    
    try:
        from wsgi import app
        from بولا import db, User, Task, Attendance, Product
    except Exception as e:
        print(f"[ERROR] Import app error: {e}")
        return

    with app.app_context():
        # إنشاء كافة الجداول على Supabase Postgres
        db.create_all()
        print("[OK] Tables created successfully on Supabase!")

        if not has_sqlite:
            print("[OK] Database setup complete on Supabase!")
            return

        print("\n[2/3] Migrating data from SQLite to PostgreSQL...")

        # نقل المستخدمين Users
        try:
            sqlite_cursor.execute("SELECT * FROM users")
            users = sqlite_cursor.fetchall()
            print(f"  - Migrating {len(users)} users...")
            for row in users:
                u = dict(row)
                existing = User.query.get(u['id'])
                if not existing:
                    new_u = User(
                        id=u['id'],
                        username=u['username'],
                        password_hash=u['password_hash'],
                        role=u['role']
                    )
                    db.session.add(new_u)
            db.session.commit()
            print("  [OK] Users migrated.")
        except Exception as e:
            print(f"  [WARNING] Users migration warning: {e}")
            db.session.rollback()

        # نقل المهام Tasks
        try:
            sqlite_cursor.execute("SELECT * FROM tasks")
            tasks = sqlite_cursor.fetchall()
            print(f"  - Migrating {len(tasks)} tasks...")
            for row in tasks:
                t = dict(row)
                existing = Task.query.get(t['id'])
                if not existing:
                    new_t = Task(
                        id=t['id'],
                        title=t['title'],
                        description=t.get('description'),
                        assigned_to=t.get('assigned_to'),
                        status=t.get('status', 'pending')
                    )
                    db.session.add(new_t)
            db.session.commit()
            print("  [OK] Tasks migrated.")
        except Exception as e:
            print(f"  [WARNING] Tasks migration warning: {e}")
            db.session.rollback()

        # نقل الحضور Attendance
        try:
            sqlite_cursor.execute("SELECT * FROM attendance")
            attendances = sqlite_cursor.fetchall()
            print(f"  - Migrating {len(attendances)} attendance records...")
            for row in attendances:
                a = dict(row)
                existing = Attendance.query.get(a['id'])
                if not existing:
                    new_a = Attendance(
                        id=a['id'],
                        user_id=a['user_id'],
                        attendance_date=a['attendance_date'],
                        check_in_time=a.get('check_in_time'),
                        check_out_time=a.get('check_out_time'),
                        status=a.get('status', 'present')
                    )
                    db.session.add(new_a)
            db.session.commit()
            print("  [OK] Attendance migrated.")
        except Exception as e:
            print(f"  [WARNING] Attendance migration warning: {e}")
            db.session.rollback()

        # نقل المنتجات Products
        try:
            sqlite_cursor.execute("SELECT * FROM products")
            products = sqlite_cursor.fetchall()
            print(f"  - Migrating {len(products)} products...")
            for row in products:
                p = dict(row)
                existing = Product.query.get(p['id'])
                if not existing:
                    new_p = Product(
                        id=p['id'],
                        name=p['name'],
                        description=p.get('description'),
                        price=p.get('price', 0.0),
                        image_filename=p.get('image_filename')
                    )
                    db.session.add(new_p)
            db.session.commit()
            print("  [OK] Products migrated.")
        except Exception as e:
            print(f"  [WARNING] Products migration warning: {e}")
            db.session.rollback()

    # 3. نقل الملفات والصور إلى Supabase Storage إذا كان مفاعلاً
    supabase_url = os.environ.get('SUPABASE_URL')
    supabase_key = os.environ.get('SUPABASE_KEY') or os.environ.get('SUPABASE_SERVICE_ROLE_KEY')
    if supabase_url and supabase_key and not supabase_key.startswith('sb_publishable_key_placeholder'):
        print("\n[3/3] Uploading files & images to Supabase Storage...")
        try:
            from supabase_storage import SupabaseStorageManager
            sm = SupabaseStorageManager(supabase_url, supabase_key)
            
            # رفع ملفات المستخدمين
            uploads_dir = os.path.join(os.path.dirname(__file__), 'uploads')
            if os.path.isdir(uploads_dir):
                for user_id in os.listdir(uploads_dir):
                    user_folder = os.path.join(uploads_dir, user_id)
                    if os.path.isdir(user_folder):
                        for fn in os.listdir(user_folder):
                            if fn == '.meta.json':
                                continue
                            file_p = os.path.join(user_folder, fn)
                            if os.path.isfile(file_p):
                                with open(file_p, 'rb') as f:
                                    content = f.read()
                                url = sm.upload_file('user-uploads', f"{user_id}/{fn}", content)
                                print(f"  - Uploaded {user_id}/{fn} -> {url}")

            # رفع صور المنتجات
            prod_img_dir = os.path.join(os.path.dirname(__file__), 'static', 'product_images')
            if os.path.isdir(prod_img_dir):
                for fn in os.listdir(prod_img_dir):
                    file_p = os.path.join(prod_img_dir, fn)
                    if os.path.isfile(file_p):
                        with open(file_p, 'rb') as f:
                            content = f.read()
                        url = sm.upload_file('product-images', fn, content)
                        print(f"  - Uploaded {fn} -> {url}")
            print("[OK] All files uploaded to Supabase Storage!")
        except Exception as e:
            print(f"[WARNING] Storage upload warning: {e}")
    else:
        print("\n[INFO] Storage migration skipped (SUPABASE_KEY needed for storage uploads).")

    print("\n" + "=" * 60)
    print("=== [SUCCESS] Migration to Supabase Completed! ===")
    print("=" * 60)

if __name__ == '__main__':
    run_migration()
