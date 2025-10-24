# ============================================
# run_full_setup.ps1  –  Setup completo del panel distribuidor
# ============================================

# --- CONFIG ---
$DB_NAME = "distributor_db_utf8"
$DB_USER = "postgres"
$DB_PASS = "Faccaf21$"
$SQL_PATH = "C:\fastapi_project\fastapi_project\app\seed_distributor_db_regen.sql"
$PG_BIN = "C:\Program Files\PostgreSQL\16\bin"
$VENV_PATH = "C:\fastapi_project\fastapi_project\venv\Scripts\Activate.ps1"
$STREAMLIT_APP = "C:\fastapi_project\fastapi_project\app\dashboard.py"

Write-Host "`n🚀 Iniciando setup completo del distribuidor..." -ForegroundColor Cyan

# --- Paso 1: Eliminar base previa ---
Write-Host "🧹 Eliminando base de datos anterior..." -ForegroundColor Yellow
& "$PG_BIN\psql.exe" -U $DB_USER -c "DROP DATABASE IF EXISTS $DB_NAME;" 

# --- Paso 2: Crear base nueva UTF-8 ---
Write-Host "🧱 Creando base nueva UTF-8..." -ForegroundColor Yellow
& "$PG_BIN\createdb.exe" -U $DB_USER -E UTF8 -T template0 -l es_ES.UTF-8 $DB_NAME

# --- Paso 3: Importar SQL maestro ---
Write-Host "📦 Importando datos completos desde $SQL_PATH ..." -ForegroundColor Yellow
& "$PG_BIN\psql.exe" -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -f $SQL_PATH

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error durante la importación SQL. Revisa mensajes anteriores." -ForegroundColor Red
    exit 1
}

# --- Paso 4: Verificar conteo ---
Write-Host "🔍 Verificando conteos finales..." -ForegroundColor Yellow
& "$PG_BIN\psql.exe" -U $DB_USER -d $DB_NAME -c "SELECT 'Productos' AS tabla, COUNT(*) FROM public.products
UNION ALL SELECT 'Clientes', COUNT(*) FROM public.customers
UNION ALL SELECT 'Pedidos', COUNT(*) FROM public.orders
UNION ALL SELECT 'Items', COUNT(*) FROM public.order_items;"

# --- Paso 5: Lanzar Streamlit ---
Write-Host "`n💡 Abriendo panel Streamlit..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd 'C:\fastapi_project\fastapi_project'; & '$VENV_PATH'; streamlit run '$STREAMLIT_APP'"

Write-Host "`n✅ Setup completo finalizado. Panel disponible en: http://localhost:8502" -ForegroundColor Cyan
