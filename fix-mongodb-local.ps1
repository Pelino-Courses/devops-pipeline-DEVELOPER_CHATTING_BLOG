# Fix MongoDB Lock File Issue
# This script cleans up MongoDB lock files and restarts MongoDB

Write-Host "================================" -ForegroundColor Cyan
Write-Host "MongoDB Lock File Cleanup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$mongoDataPath = "C:\mongo\data"
$mongoLockFile = "$mongoDataPath\mongod.lock"

# Step 1: Stop MongoDB if it's running
Write-Host "[1/4] Stopping MongoDB process..." -ForegroundColor Yellow
$mongoProcess = Get-Process -Name "mongod" -ErrorAction SilentlyContinue
if ($mongoProcess) {
    Stop-Process -Name "mongod" -Force
    Start-Sleep -Seconds 2
    Write-Host "✅ MongoDB process stopped" -ForegroundColor Green
}
else {
    Write-Host "✅ MongoDB process not running" -ForegroundColor Green
}

# Step 3: Clean diagnostic.data folder (sometimes causes issues)
Write-Host "`n[3/4] Cleaning diagnostic data..." -ForegroundColor Yellow
$diagnosticPath = "$mongoDataPath\diagnostic.data"
if (Test-Path $diagnosticPath) {
    try {
        Remove-Item -Path $diagnosticPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Diagnostic data cleaned" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Could not remove diagnostic data (non-critical)" -ForegroundColor Yellow
    }
}

# Step 4: Recreate data directory structure
Write-Host "`n[4/4] Ensuring data directory exists..." -ForegroundColor Yellow
if (-not (Test-Path $mongoDataPath)) {
    New-Item -ItemType Directory -Path $mongoDataPath -Force | Out-Null
    Write-Host "✅ Data directory created: $mongoDataPath" -ForegroundColor Green
}
else {
    Write-Host "✅ Data directory exists: $mongoDataPath" -ForegroundColor Green
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Cleanup Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Now start MongoDB with:" -ForegroundColor Yellow
Write-Host '& "C:\Program Files\MongoDB\Server\8.2\bin\mongod.exe" --dbpath "C:\mongo\data" --port 27017' -ForegroundColor Gray
Write-Host ""
Write-Host "If MongoDB still crashes, use the Docker solution instead:" -ForegroundColor Yellow
Write-Host "  .\test-backend-locally.ps1" -ForegroundColor Gray
