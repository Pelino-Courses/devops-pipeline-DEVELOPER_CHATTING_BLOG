# Backend Diagnostic Script
param(
    [string]$ServerIP = "51.103.157.72",
    [string]$Username = "azureuser"
)

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Backend Issue Diagnostic Tool" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Server: $ServerIP" -ForegroundColor Gray
Write-Host ""

# Test 1: Check Docker containers
Write-Host "[1/5] Checking Docker containers..." -ForegroundColor Yellow
$containers = ssh ${Username}@${ServerIP} "docker ps --format 'table {{.Names}}\t{{.Status}}'" 2>&1
Write-Host $containers
Write-Host ""

# Test 2: Check backend logs
Write-Host "[2/5] Checking backend logs (last 30 lines)..." -ForegroundColor Yellow
Write-Host "================================" - Gray
$backendLogs = ssh ${Username}@${ServerIP} "docker logs --tail 30 backend 2>&1"
Write-Host $backendLogs
Write-Host "================================" -ForegroundColor Gray

# Test 3: Check environment variables
Write-Host "`n[3/5] Checking environment variables..." -ForegroundColor Yellow
$envCheck = ssh ${Username}@${ServerIP} "docker exec backend printenv | grep -E '(MONGO_URI|JWT_SECRET|EMAIL_USER|PORT)'" 2>&1
if ($envCheck) {
    Write-Host $envCheck -replace '(JWT_SECRET|EMAIL_PASS)=.*', '$1=***MASKED***'
}
else {
    Write-Host "No environment variables found" -ForegroundColor Red
}

# Test 4: Check MongoDB connection
Write-Host "`n[4/5] Testing MongoDB..." -ForegroundColor Yellow
$mongoTest = ssh ${Username}@${ServerIP} "docker exec mongodb mongosh --eval 'db.adminCommand({ping:1})'" 2>&1
if ($mongoTest -match "ok.*1") {
    Write-Host " MongoDB responding" -ForegroundColor Green
}
else {
    Write-Host "MongoDB NOT responding" -ForegroundColor Red
}

# Test 5: Check .env file
Write-Host "`n[5/5] Checking .env file..." -ForegroundColor Yellow
$envFile = ssh ${Username}@${ServerIP} "ls -la /opt/devops-app/.env 2>&1; echo '---'; cat /opt/devops-app/.env 2>&1 | grep -v PASS | grep -v SECRET" 2>&1
Write-Host $envFile

# Summary
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "LIKELY CAUSES:" -ForegroundColor Yellow
Write-Host "1. Email service timeout (nodemailer hanging)" -ForegroundColor White
Write-Host "2. Missing environment variables" -ForegroundColor White
Write-Host "3. MongoDB connection issue" -ForegroundColor White
Write-Host ""
Write-Host "RECOMMENDED FIXES:" -ForegroundColor Yellow
Write-Host "Run: .\update_server_env.ps1" -ForegroundColor White
Write-Host "================================" -ForegroundColor Cyan
