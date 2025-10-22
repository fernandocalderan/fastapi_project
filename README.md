# Banco de datos de distribuidora de alimentos

Aplicación de ejemplo construida con FastAPI y SQLAlchemy que modela el banco de datos de una distribuidora ficticia de alimentos. Incluye tablas para proveedores, catálogo de productos, inventario en bodegas, clientes, pedidos y envíos. El objetivo es servir como material didáctico para aprender a generar y gestionar una base de datos PostgreSQL con un front-end API mínimo.

## Contenido
- [Requisitos previos](#requisitos-previos)
- [Instalacion](#instalacion)
- [Configuracion](#configuracion)
- [Ejecucion](#ejecucion)
- [Endpoints](#endpoints)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Scripts utiles](#scripts-utiles)
- [Carga de datos con archivos SQL](#carga-de-datos-con-archivos-sql)
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
1. Crea una base de datos vacia en PostgreSQL. Puedes hacerlo de dos maneras:
   - **Con el script incluido en el proyecto:**
     ```bash
     python scripts/create_database.py --db-name fastapi_db --user postgres --password tu_password --host localhost --port 5432
     ```
     El script respeta las variables de entorno estándar (`PGUSER`, `PGPASSWORD`, `PGHOST`, etc.), de modo que también puedes exportarlas previamente y ejecutar simplemente `python scripts/create_database.py`.
   - **Directamente con `psql` u otra herramienta:**
     ```bash
     psql -U postgres -h localhost -c "CREATE DATABASE fastapi_db;"
     ```
     Asegúrate de estar usando una cuenta con permisos para crear bases de datos.
2. Copia el archivo de ejemplo `.env` (o crea uno nuevo) en la raiz del proyecto y ajusta las credenciales:
   ```env
   DATABASE_URL=postgresql://postgres:tu_password@localhost:5432/fastapi_db
   ```
3. Al iniciar la aplicacion, SQLAlchemy creará automáticamente todas las tablas del dominio (`suppliers`, `products`, `warehouses`, etc.) definidas en `app/models.py` si aún no existen.

## Ejecucion
### Linux / macOS
Inicia el servidor de desarrollo con Uvicorn:
```bash
uvicorn app.main:app --reload
```

Por defecto la API queda disponible en `http://127.0.0.1:8000`.

### Windows (PowerShell)
Puedes usar el script `run_fastapi.ps1` incluido en la raiz del proyecto para automatizar la activación del entorno virtual, la compilación y la ejecución del servidor:
```powershell
pwsh ./run_fastapi.ps1
```

El script buscará la primera plaza libre entre los puertos 8000 y 8010, mostrará el comando utilizado e iniciará una ventana de Uvicorn lista para trabajar.

## Endpoints
| Metodo | Ruta              | Descripción                                                                 |
|--------|-------------------|-----------------------------------------------------------------------------|
| GET    | `/`               | Verificación rápida del servicio.                                          |
| GET    | `/suppliers/`     | Lista proveedores registrados.                                             |
| GET    | `/products/`      | Lista productos, filtrables por proveedor o categoría.                     |
| GET    | `/warehouses/`    | Consulta bodegas y centros logísticos.                                     |
| GET    | `/inventory/`     | Consulta inventario con filtros por producto o almacén.                    |
| GET    | `/customers/`     | Lista clientes comerciales.                                                |
| GET    | `/orders/`        | Detalla pedidos con sus partidas.                                          |
| GET    | `/shipments/`     | Muestra envíos y estado logístico.                                         |
| GET    | `/categories/`    | Lista categorías del catálogo.                                             |

> Los endpoints `/{id}` de cada recurso permiten consultar un registro específico y se devuelven en formatos compatibles con Pydantic definidos en `app/schemas.py`.

## Estructura del proyecto
```
app/
├── main.py             # Punto de entrada FastAPI
├── database.py         # Conexión y sesión de SQLAlchemy
├── models.py           # Declaraciones ORM de la distribuidora
├── schemas.py          # Modelos Pydantic expuestos por la API
├── crud.py             # Consultas reutilizables para cada entidad
├── dependencies.py     # Dependencias comunes (sesión de DB)
├── routers/            # Conjunto de routers separados por dominio
│   ├── suppliers.py
│   ├── categories.py
│   ├── products.py
│   ├── warehouses.py
│   ├── inventory.py
│   ├── customers.py
│   ├── orders.py
│   └── shipments.py
└── connect_postgres.py # Script de verificación via psycopg2

sql/
├── schema.sql          # Definición SQL del modelo de datos
└── sample_seed.sql     # Datos de ejemplo para poblar la base
```

## Scripts utiles
- `scripts/create_database.py`: crea la base de datos objetivo (`fastapi_db` por defecto) si aún no existe.
- `app/connect_postgres.py`: consulta rápida a PostgreSQL usando psycopg2 para validar credenciales y listar las tablas creadas.
- `run_fastapi.ps1`: automatiza en Windows la activación del entorno virtual, compila los módulos y arranca Uvicorn en un puerto disponible.

## Carga de datos con archivos SQL

Si ya cuentas con un archivo `.sql` que contiene los registros para poblar la base de datos:

1. Asegúrate de haber ejecutado primero `sql/schema.sql` sobre una base de datos vacía para crear la estructura esperada:
   ```bash
   psql "$DATABASE_URL" -f sql/schema.sql
   ```
2. Ejecuta tu archivo de carga (por ejemplo `datos_empresa.sql`). Puedes colocarlo dentro del directorio `sql/` para mantenerlo versionado:
   ```bash
   psql "$DATABASE_URL" -f sql/datos_empresa.sql
   ```
3. Si quieres un conjunto mínimo para pruebas rápidas, puedes utilizar `sql/sample_seed.sql` incluido en el repositorio:
   ```bash
   psql "$DATABASE_URL" -f sql/sample_seed.sql
   ```

Tras importar los datos podrás inspeccionarlos desde la API o directamente con consultas SQL.

## Siguientes pasos sugeridos
1. Añadir pruebas automatizadas para la capa CRUD y los endpoints.
2. Externalizar dependencias en `requirements.txt` o `pyproject.toml`.
3. Contenerizar la aplicacion (por ejemplo, usando Docker y docker-compose) para simplificar despliegues.
