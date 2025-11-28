# Complete Backend Test Script with Local MongoDB
# This script starts MongoDB, then guides you to test the backend

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Backend Testing with Local MongoDB" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Clean MongoDB first
Write-Host "Cleaning MongoDB lock files..." -ForegroundColor Yellow
& "$PSScriptRoot\fix-mongodb-local.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ MongoDB cleanup failed. Use Docker instead:" -ForegroundColor Red
    Write-Host "   .\test-backend-locally.ps1" -ForegroundColor Gray
    exit 1
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Starting MongoDB..." -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Start MongoDB in a new window
$mongoCmd = '& "C:\Program Files\MongoDB\Server\8.2\bin\mongod.exe" --dbpath "C:\mongo\data" --port 27017'
Start-Process powershell -ArgumentList "-NoExit", "-Command", $mongoCmd -WindowStyle Normal

Write-Host "⏳ Waiting for MongoDB to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Test if MongoDB is running
try {
    $mongoTest = & "C:\Program Files\MongoDB\Server\8.2\bin\mongosh.exe" --eval "db.adminCommand('ping')" --quiet 2>&1
    if ($mongoTest -match "ok.*1") {
        Write-Host "✅ MongoDB is running successfully!" -ForegroundColor Green
    }
    else {
        throw "MongoDB ping failed"
    }
}
catch {
    Write-Host "❌ MongoDB failed to start or is crashing" -ForegroundColor Red
    Write-Host "`nThis might be a compatibility issue with MongoDB 8.2 on your Windows version." -ForegroundColor Yellow
    Write-Host "Use the Docker solution instead:" -ForegroundColor Yellow
    Write-Host "  .\test-backend-locally.ps1" -ForegroundColor Gray
    exit 1
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "MongoDB is Ready!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps to test your backend:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Open a NEW PowerShell terminal"
Write-Host "2. Navigate to backend:"
Write-Host "   cd c:\Users\Dell\Desktop\devops-pipeline-DEVELOPER_CHATTING_BLOG-1\backend"
Write-Host ""
Write-Host "3. Start the backend:"
Write-Host "   npm start" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Open ANOTHER PowerShell terminal and test:"
Write-Host ""
Write-Host "   # Test health endpoint" -ForegroundColor Green
Write-Host "   curl http://localhost:5000/health"
Write-Host ""
Write-Host "   # Test registration" -ForegroundColor Green
Write-Host '   $testUser = @{username="testuser123"; email="test123@example.com"; password="Test123!"} | ConvertTo-Json'
Write-Host '   Invoke-RestMethod -Uri "http://localhost:5000/api/register" -Method POST -Body $testUser -ContentType "application/json"'
Write-Host ""
Write-Host "   # Test login" -ForegroundColor Green
Write-Host '   $loginData = @{email="test123@example.com"; password="Test123!"} | ConvertTo-Json'
Write-Host '   Invoke-RestMethod -Uri "http://localhost:5000/api/login" -Method POST -Body $loginData -ContentType "application/json"'
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "MongoDB connection: mongodb://localhost:27017/chatapp" -ForegroundColor Gray
Write-Host "================================" -ForegroundColor Cyan
