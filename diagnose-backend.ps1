# Diagnostic script to test backend and MongoDB connection
$vmIP = "51.103.157.72"

Write-Host "=== BACKEND DIAGNOSTICS ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if backend port is responding
Write-Host "[TEST 1] Backend Health Check (http://$vmIP:5000/health)" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$vmIP:5000/health" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Backend is responding with status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: Try a simple API call to signup
Write-Host "[TEST 2] Test Backend API - Signup Endpoint" -ForegroundColor Yellow
try {
    $signupData = @{
        username = "testuser$(Get-Random)"
        email = "test$(Get-Random)@example.com"
        password = "Test@123456"
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "http://$vmIP:5000/api/signup" `
        -Method POST `
        -ContentType "application/json" `
        -Body $signupData `
        -TimeoutSec 10 `
        -ErrorAction Stop
    
    Write-Host "✅ Signup API is responding" -ForegroundColor Green
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__ 2>$null
    $errorContent = $_.Exception.Response.Content.ReadAsStream() | ForEach-Object {
        $reader = New-Object System.IO.StreamReader($_)
        $reader.ReadToEnd()
    } 2>$null
    
    Write-Host "❌ Signup API call failed" -ForegroundColor Red
    Write-Host "Status Code: $statusCode" -ForegroundColor Red
    Write-Host "Error: $errorContent" -ForegroundColor Red
    Write-Host "Full Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Check backend container logs
Write-Host "[TEST 3] Backend Container Logs (via SSH)" -ForegroundColor Yellow
Write-Host "To check backend logs, run:" -ForegroundColor Cyan
Write-Host "ssh azureuser@$vmIP 'docker logs backend'" -ForegroundColor Cyan

Write-Host ""

# Test 4: Check MongoDB connection
Write-Host "[TEST 4] MongoDB Connection Test" -ForegroundColor Yellow
Write-Host "To check if MongoDB is running, run:" -ForegroundColor Cyan
Write-Host "ssh azureuser@$vmIP 'docker exec mongodb mongo --version'" -ForegroundColor Cyan

Write-Host ""

# Test 5: Check all containers
Write-Host "[TEST 5] Container Status" -ForegroundColor Yellow
Write-Host "To check container status, run:" -ForegroundColor Cyan
Write-Host "ssh azureuser@$vmIP 'docker ps -a'" -ForegroundColor Cyan

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "If Tests 1-2 fail, check backend logs with Test 3 command" -ForegroundColor Yellow
Write-Host "If backend logs show MongoDB errors, check MongoDB with Test 4 command" -ForegroundColor Yellow
Write-Host "Use Test 5 to verify all containers are running" -ForegroundColor Yellow
