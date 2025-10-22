from collections.abc import Generator

from sqlalchemy.orm import Session

from .database import SessionLocal


def get_db() -> Generator[Session, None, None]:
    """Provee una sesión de base de datos por petición."""

    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
