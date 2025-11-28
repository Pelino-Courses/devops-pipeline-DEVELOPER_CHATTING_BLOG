# Local Backend Testing Script
# This script starts MongoDB in Docker and tests the backend locally

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Local Backend Testing with Docker" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "[1/5] Checking Docker..." -ForegroundColor Yellow
try {
    docker ps | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Docker is running" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker is not installed or not running." -ForegroundColor Red
    exit 1
}

# Stop and remove existing test containers if any
Write-Host "`n[2/5] Cleaning up existing test containers..." -ForegroundColor Yellow
docker stop mongodb-test 2>$null | Out-Null
docker rm mongodb-test 2>$null | Out-Null
Write-Host "✅ Cleanup complete" -ForegroundColor Green

# Start MongoDB in Docker
Write-Host "`n[3/5] Starting MongoDB container..." -ForegroundColor Yellow
docker run -d `
    --name mongodb-test `
    -p 27017:27017 `
    mongo:7

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to start MongoDB container" -ForegroundColor Red
    exit 1
}

# Wait for MongoDB to be ready
Write-Host "⏳ Waiting for MongoDB to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
Write-Host "✅ MongoDB container started" -ForegroundColor Green

# Test MongoDB connection
Write-Host "`n[4/5] Testing MongoDB connection..." -ForegroundColor Yellow
$retries = 0
$maxRetries = 10
$connected = $false

while ($retries -lt $maxRetries -and -not $connected) {
    try {
        $result = docker exec mongodb-test mongosh --eval "db.adminCommand('ping')" 2>&1
        if ($result -match "ok.*1") {
            $connected = $true
            Write-Host "✅ MongoDB is responding" -ForegroundColor Green
        }
    }
    catch {
        $retries++
        Start-Sleep -Seconds 1
    }
}

if (-not $connected) {
    Write-Host "❌ MongoDB failed to start properly" -ForegroundColor Red
    docker logs mongodb-test
    exit 1
}

Write-Host "`n[5/5] Instructions to test backend:" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan
Write-Host "1. Open a NEW PowerShell terminal"
Write-Host "2. Navigate to backend directory:"
Write-Host "   cd c:\Users\Dell\Desktop\devops-pipeline-DEVELOPER_CHATTING_BLOG-1\backend"
Write-Host "3. Start the backend:"
Write-Host "   npm start"
Write-Host ""
Write-Host "4. Open ANOTHER terminal and test the endpoints:"
Write-Host "   # Test health endpoint"
Write-Host "   curl http://localhost:5000/health"
Write-Host ""
Write-Host "   # Test registration"
Write-Host '   $body = @{username="testuser"; email="test@example.com"; password="Test123!"}' -ForegroundColor Gray
Write-Host '   Invoke-RestMethod -Uri "http://localhost:5000/api/register" -Method POST -Body ($body | ConvertTo-Json) -ContentType "application/json"' -ForegroundColor Gray
Write-Host ""
Write-Host "5. When done testing, stop MongoDB:"
Write-Host "   docker stop mongodb-test"
Write-Host "   docker rm mongodb-test"
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ MongoDB is ready on localhost:27017" -ForegroundColor Green
Write-Host "   Connection string: mongodb://localhost:27017/chatapp" -ForegroundColor Gray
