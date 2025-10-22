# ===============================================
# run_fastapi.ps1
# Purpose: Compile all .py files, detect free port, and run Uvicorn automatically.
# Compatible: Windows PowerShell 5+ / PowerShell Core 7+
# ===============================================

Write-Host "=== FastAPI Auto Runner ===" -ForegroundColor Cyan

# --- 1️⃣ Activate virtual environment ---
$venvPath = ".\venv\Scripts\Activate.ps1"
if (Test-Path $venvPath) {
    Write-Host "Activating virtual environment..." -ForegroundColor Yellow
    & $venvPath
} else {
    Write-Host "❌ Virtual environment not found. Create it with: python -m venv venv" -ForegroundColor Red
    exit 1
}

# --- 2️⃣ Compile all Python files ---
Write-Host "Compiling Python source files..." -ForegroundColor Yellow
python -m compileall -q .
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compilation successful." -ForegroundColor Green
} else {
    Write-Host "⚠️ Compilation finished with warnings." -ForegroundColor DarkYellow
}

# --- 3️⃣ Detect free port (8000–8010) ---
Write-Host "Detecting free port..." -ForegroundColor Yellow
$basePort = 8000
$port = $null
for ($i = 0; $i -lt 10; $i++) {
    $tryPort = $basePort + $i
    $tcp = Test-NetConnection -ComputerName 127.0.0.1 -Port $tryPort -WarningAction SilentlyContinue
    if (-not $tcp.TcpTestSucceeded) {
        $port = $tryPort
        break
    }
}

if (-not $port) {
    Write-Host "❌ No free port found between 8000 and 8010." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Using port $port" -ForegroundColor Green

# --- 4️⃣ Launch Uvicorn ---
Write-Host "Starting Uvicorn server..." -ForegroundColor Yellow
$cmd = "uvicorn app.main:app --reload --host 127.0.0.1 --port $port"
Write-Host "Command: $cmd" -ForegroundColor DarkCyan

Start-Process powershell -ArgumentList "-NoExit", "-Command", $cmd
Write-Host "🚀 Server launched on http://127.0.0.1:$port" -ForegroundColor Green
Write-Host "Press Ctrl + C in the Uvicorn window to stop the server."
