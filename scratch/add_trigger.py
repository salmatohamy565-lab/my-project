import psycopg2

db_url = "postgresql://postgres.kxeqayzxfvoedqvilcmp:boladesign012B@aws-0-eu-west-1.pooler.supabase.com:6543/postgres"
conn = psycopg2.connect(db_url)
cur = conn.cursor()

sql_function = """
CREATE OR REPLACE FUNCTION auto_fill_user_email()
RETURNS TRIGGER AS $func$
BEGIN
    IF NEW.email IS NULL OR TRIM(NEW.email) = '' THEN
        IF NEW.username LIKE '%@%' THEN
            NEW.email := LOWER(TRIM(NEW.username));
        ELSIF NEW.username IS NOT NULL AND TRIM(NEW.username) <> '' THEN
            NEW.email := LOWER(TRIM(NEW.username)) || '@gmail.com';
        END IF;
    END IF;
    RETURN NEW;
END;
$func$ LANGUAGE plpgsql;
"""

sql_trigger = """
DROP TRIGGER IF EXISTS trigger_auto_fill_user_email ON users;
CREATE TRIGGER trigger_auto_fill_user_email
BEFORE INSERT OR UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION auto_fill_user_email();
"""

cur.execute(sql_function)
cur.execute(sql_trigger)
conn.commit()
print("PostgreSQL auto_fill_user_email trigger created successfully!")
conn.close()
