# FastAPI + PostgreSQL Demo

Aplicacion de ejemplo construida con FastAPI y SQLAlchemy que expone un CRUD basico de usuarios respaldado por PostgreSQL. El objetivo es mostrar una arquitectura minima con modelos, esquemas Pydantic, capa CRUD y ruteo modular.

## Contenido
- [Requisitos previos](#requisitos-previos)
- [Instalacion](#instalacion)
- [Configuracion](#configuracion)
- [Ejecucion](#ejecucion)
- [Endpoints](#endpoints)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Scripts utiles](#scripts-utiles)
- [Siguientes pasos sugeridos](#siguientes-pasos-sugeridos)

## Requisitos previos
- Python 3.10 o superior
- PostgreSQL 13+ en ejecucion local o accesible via red
- `pip` y (opcional) `python -m venv` para entornos virtuales

## Instalacion
```bash
git clone <url-del-repositorio>
cd fastapi_project
python -m venv .venv
source .venv/bin/activate  # En Windows: .venv\Scripts\activate
pip install fastapi uvicorn sqlalchemy psycopg2-binary python-dotenv
```

> Si dispones de un archivo `requirements.txt`, puedes ejecutar `pip install -r requirements.txt`.

## Configuracion
1. Crea una base de datos vacia en PostgreSQL:
   ```bash
   psql -U postgres -c "CREATE DATABASE fastapi_db;"
   ```
2. Copia el archivo de ejemplo `.env` (o crea uno nuevo) en la raiz del proyecto y ajusta las credenciales:
   ```env
   DATABASE_URL=postgresql://postgres:tu_password@localhost:5432/fastapi_db
   ```
3. Al iniciar la aplicacion, SQLAlchemy creara automaticamente la tabla `users` definida en `app/models.py` si aun no existe.

## Ejecucion
Inicia el servidor de desarrollo con Uvicorn:
```bash
uvicorn app.main:app --reload
```

Por defecto la API queda disponible en `http://127.0.0.1:8000`.

## Endpoints
| Metodo | Ruta        | Descripcion                       |
|--------|-------------|-----------------------------------|
| GET    | `/`         | Verificacion rapida del servicio. |
| GET    | `/users/`   | Lista todos los usuarios.         |
| POST   | `/users/`   | Crea un usuario nuevo.            |

### Ejemplo de peticion `POST /users/`
```json
{
  "name": "Ada Lovelace",
  "email": "ada@example.com"
}
```

## Estructura del proyecto
```
app/
├── main.py            # Punto de entrada FastAPI
├── database.py        # Conexion y sesion de SQLAlchemy
├── models.py          # Declaraciones ORM
├── schemas.py         # Modelos Pydantic
├── crud.py            # Operaciones de acceso a datos
├── routers/
│   └── users.py       # Rutas agrupadas por recurso
└── connect_postgres.py# Script de verificacion via psycopg2
```

## Scripts utiles
- `app/connect_postgres.py`: consulta rapida a PostgreSQL usando psycopg2 para validar credenciales.

## Siguientes pasos sugeridos
1. Añadir pruebas automatizadas para la capa CRUD y los endpoints.
2. Externalizar dependencias en `requirements.txt` o `pyproject.toml`.
3. Contenerizar la aplicacion (por ejemplo, usando Docker y docker-compose) para simplificar despliegues.
