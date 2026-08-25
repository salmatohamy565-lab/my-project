import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
from sqlalchemy import create_engine, text

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
engine = create_engine(db_url)

sql = """
-- 1. Shared Files Table
CREATE TABLE IF NOT EXISTS public.shared_files (
    id SERIAL PRIMARY KEY,
    sender_id INT NULL,
    sender_name VARCHAR(255) NULL,
    recipient_id INT NULL, -- NULL means public/all employees
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(50) DEFAULT 'document',
    archived BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tasks Table
CREATE TABLE IF NOT EXISTS public.tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    assigned_to INT NULL, -- Employee ID
    assigned_by INT NULL, -- Admin ID
    status VARCHAR(50) DEFAULT 'pending', -- pending, completed, in_progress
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id SERIAL PRIMARY KEY,
    user_id INT NULL, -- Recipient user ID (NULL means broadcast)
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Grant full permissions to anon & authenticated roles
GRANT ALL ON TABLE public.shared_files TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.tasks TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.notifications TO anon, authenticated, service_role;

GRANT USAGE, SELECT ON SEQUENCE public.shared_files_id_seq TO anon, authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE public.tasks_id_seq TO anon, authenticated, service_role;
GRANT USAGE, SELECT ON SEQUENCE public.notifications_id_seq TO anon, authenticated, service_role;
"""

with engine.connect() as conn:
    try:
        conn.execute(text(sql))
        conn.commit()
        print("[SUCCESS] Checked and created shared_files, tasks, and notifications tables in Supabase PostgreSQL!")
    except Exception as e:
        print("[ERROR] Failed creating tables:", e)
