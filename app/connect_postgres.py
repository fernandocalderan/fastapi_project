import os

import psycopg2
from dotenv import load_dotenv


def main() -> None:
    load_dotenv()

    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise RuntimeError("DATABASE_URL no está definido en el entorno.")

    conn = psycopg2.connect(database_url)
    cur = conn.cursor()

    cur.execute(
        """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        ORDER BY table_name;
        """
    )
    tables = cur.fetchall()

    print("Tablas disponibles en la base de datos:")
    for table in tables:
        print(f"- {table[0]}")

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
