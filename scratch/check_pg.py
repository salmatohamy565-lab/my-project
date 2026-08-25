import sys

try:
    import psycopg2
    print("psycopg2 is installed")
except ImportError:
    print("psycopg2 NOT installed")

try:
    import pg8000
    print("pg8000 is installed")
except ImportError:
    print("pg8000 NOT installed")
