# === Cargar base de datos distributor_db_utf8 desde seed_distributor_db_full.sql ===
# Ruta al archivo SQL
$sqlFile = "C:\fastapi_project\fastapi_project\app\seed_distributor_db_full.sql"

# Ruta temporal para conversión
$tempFile = "$env:TEMP\seed_utf8.sql"

# Detectar codificación del archivo original
$encoding = (Get-Content $sqlFile -Encoding Byte -ReadCount 0)[0..3]
Write-Host "🔍 Detectando codificación..." -ForegroundColor Yellow

# Convertir a UTF-8 sin BOM (si no lo está)
try {
    $content = Get-Content $sqlFile -Raw
    $content | Out-File -FilePath $tempFile -Encoding utf8
    Write-Host "✅ Archivo convertido temporalmente a UTF-8 sin BOM: $tempFile" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Error al convertir el archivo. Verifica permisos o rutas." -ForegroundColor Red
    exit
}

# Ejecutar importación con PostgreSQL (sin client_encoding manual)
$psqlPath = "C:\Program Files\PostgreSQL\16\bin\psql.exe"
$dbName = "distributor_db_utf8"
$user = "postgres"

Write-Host "🚀 Ejecutando importación de base de datos..." -ForegroundColor Cyan
& "$psqlPath" -U $user -d $dbName -f $tempFile

# Limpieza (opcional)
Remove-Item $tempFile -ErrorAction SilentlyContinue
Write-Host "🧹 Archivo temporal eliminado. Importación completada." -ForegroundColor Green
