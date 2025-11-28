# Check Backend Status on Azure VM
# This script SSH into the server and checks backend status

param(
    [Parameter(Mandatory = $false)]
    [string]$ServerIP = "51.103.157.72",
    
    [Parameter(Mandatory = $false)]
    [string]$Username = "azureuser"
)

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Backend Server Diagnostics" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Server: $ServerIP" -ForegroundColor Gray
Write-Host "User: $Username" -ForegroundColor Gray
Write-Host ""

# Test 1: Check Docker containers
Write-Host "[1/5] Checking Docker containers..." -ForegroundColor Yellow
$containers = ssh ${Username}@${ServerIP} "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host $containers
    Write-Host ""
}
else {
    Write-Host "❌ Failed to connect via SSH" -ForegroundColor Red
    Write-Host "Error: $containers" -ForegroundColor Gray
    exit 1
}

# Test 2: Check backend container specifically
Write-Host "[2/5] Checking backend container..." -ForegroundColor Yellow
$backendStatus = ssh ${Username}@${ServerIP} "docker ps -a --filter 'name=backend' --format '{{.Status}}'" 2>&1
if ($backendStatus -match "Up") {
    Write-Host "✅ Backend container is running" -ForegroundColor Green
}
else {
    Write-Host "❌ Backend container is NOT running" -ForegroundColor Red
    Write-Host "   Status: $backendStatus" -ForegroundColor Gray
}

# Test 3: Check backend logs
Write-Host "`n[3/5] Checking backend logs (last 20 lines)..." -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Gray
ssh ${Username}@${ServerIP} "docker logs --tail 20 backend 2>&1"
Write-Host "================================" -ForegroundColor Gray

# Test 4: Check MongoDB container
Write-Host "`n[4/5] Checking MongoDB container..." -ForegroundColor Yellow
$mongoStatus = ssh ${Username}@${ServerIP} "docker ps -a --filter 'name=mongodb' --format '{{.Status}}'" 2>&1
if ($mongoStatus -match "Up") {
    Write-Host "✅ MongoDB container is running" -ForegroundColor Green
}
else {
    Write-Host "❌ MongoDB container is NOT running" -ForegroundColor Red
    Write-Host "   Status: $mongoStatus" -ForegroundColor Gray
}

# Test 5: Test backend from inside the server
Write-Host "`n[5/5] Testing backend from inside server..." -ForegroundColor Yellow
$healthCheck = ssh ${Username}@${ServerIP} "curl -s http://localhost:5000/health" 2>&1
if ($healthCheck -match "running") {
    Write-Host "✅ Backend responds to /health endpoint" -ForegroundColor Green
    Write-Host "   Response: $healthCheck" -ForegroundColor Gray
}
else {
    Write-Host "❌ Backend not responding to /health" -ForegroundColor Red
    Write-Host "   Response: $healthCheck" -ForegroundColor Gray
}

# Summary and recommendations
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "RECOMMENDATIONS" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

if ($backendStatus -notmatch "Up") {
    Write-Host "`n📋 Backend container is not running. To start it:" -ForegroundColor Yellow
    Write-Host "   ssh $Username@$ServerIP" -ForegroundColor Gray
    Write-Host "   cd /opt/devops-app" -ForegroundColor Gray
    Write-Host "   docker-compose up -d backend" -ForegroundColor Gray
}

if ($mongoStatus -notmatch "Up") {
    Write-Host "`n📋 MongoDB container is not running. To start it:" -ForegroundColor Yellow
    Write-Host "   ssh $Username@$ServerIP" -ForegroundColor Gray
    Write-Host "   cd /opt/devops-app" -ForegroundColor Gray
    Write-Host "   docker-compose up -d mongodb" -ForegroundColor Gray
}

Write-Host ""
