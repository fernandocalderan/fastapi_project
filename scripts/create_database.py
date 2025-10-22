"""Utilidad para crear la base de datos principal del proyecto.

Se conecta a PostgreSQL usando credenciales de superusuario o un rol con
permisos para crear bases y genera la base objetivo si no existe.
"""
from __future__ import annotations

import argparse
import os
import sys

import psycopg2
from psycopg2 import sql
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Crea una base de datos PostgreSQL vacía si aún no existe. "
            "Puedes usar variables de entorno estándar (PGHOST, PGUSER, etc.)"
        )
    )
    parser.add_argument(
        "--db-name",
        default=os.getenv("TARGET_DB", "fastapi_db"),
        help="Nombre de la base de datos a crear.",
    )
    parser.add_argument(
        "--user",
        default=os.getenv("PGUSER", "postgres"),
        help="Usuario con permisos para crear bases de datos.",
    )
    parser.add_argument(
        "--password",
        default=os.getenv("PGPASSWORD"),
        help="Contraseña del usuario (puede establecerse via variable de entorno).",
    )
    parser.add_argument(
        "--host",
        default=os.getenv("PGHOST", "localhost"),
        help="Host o IP del servidor PostgreSQL.",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.getenv("PGPORT", "5432")),
        help="Puerto del servidor PostgreSQL.",
    )
    parser.add_argument(
        "--admin-db",
        default=os.getenv("PGDATABASE", "postgres"),
        help="Base de datos destino de la conexión administrativa.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    conn_kwargs = {
        "dbname": args.admin_db,
        "user": args.user,
        "password": args.password,
        "host": args.host,
        "port": args.port,
    }

    try:
        with psycopg2.connect(**conn_kwargs) as conn:
            conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT 1 FROM pg_database WHERE datname = %s",
                    (args.db_name,),
                )
                exists = cur.fetchone() is not None

                if exists:
                    print(f"La base '{args.db_name}' ya existe; no se realizaron cambios.")
                    return 0

                cur.execute(
                    sql.SQL("CREATE DATABASE {}" ).format(
                        sql.Identifier(args.db_name)
                    )
                )
    except psycopg2.Error as exc:
        print(f"Error al crear la base de datos: {exc}", file=sys.stderr)
        return 1

    print(
        "Base creada correctamente. Puedes continuar con las migraciones o la carga de datos."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
