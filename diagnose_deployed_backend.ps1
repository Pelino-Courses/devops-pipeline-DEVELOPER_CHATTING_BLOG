# Deployed Backend Diagnostic Script
# This script tests the deployed backend to identify issues

param(
    [Parameter(Mandatory = $false)]
    [string]$ServerIP = ""
)

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Deployed Backend Diagnostics" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# If no IP provided, ask user
if ([string]::IsNullOrEmpty($ServerIP)) {
    $ServerIP = Read-Host "Enter your Azure VM Public IP address"
}

Write-Host "Testing server: $ServerIP" -ForegroundColor Yellow
Write-Host ""

# Test results array
$results = @()

# Test 1: Health endpoint
Write-Host "[Test 1/4] Testing /health endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://${ServerIP}:5000/health" -TimeoutSec 10 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Health endpoint is responding" -ForegroundColor Green
        $results += @{Test = "Health Check"; Status = "PASS"; Details = $response.Content }
    }
}
catch {
    Write-Host "❌ Health endpoint failed" -ForegroundColor Red
    $results += @{Test = "Health Check"; Status = "FAIL"; Details = $_.Exception.Message }
}

# Test 2: Frontend endpoint
Write-Host "`n[Test 2/4] Testing frontend (port 80)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://${ServerIP}" -TimeoutSec 10 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Frontend is accessible" -ForegroundColor Green
        $results += @{Test = "Frontend"; Status = "PASS"; Details = "Status Code: 200" }
    }
}
catch {
    Write-Host "❌ Frontend failed" -ForegroundColor Red
    $results += @{Test = "Frontend"; Status = "FAIL"; Details = $_.Exception.Message }
}

# Test 3: Registration endpoint
Write-Host "`n[Test 3/4] Testing /api/signup endpoint..." -ForegroundColor Yellow
try {
    $testUser = @{
        username = "diagnostic_test_$(Get-Random)"
        email    = "test_$(Get-Random)@example.com"
        password = "TestPass123!"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "http://${ServerIP}:5000/api/signup" `
        -Method POST `
        -Body $testUser `
        -ContentType "application/json" `
        -TimeoutSec 10 `
        -ErrorAction Stop
    
    Write-Host "✅ Registration endpoint is responding" -ForegroundColor Green
    $results += @{Test = "Registration"; Status = "PASS"; Details = "Response received" }
}
catch {
    Write-Host "❌ Registration endpoint failed" -ForegroundColor Red
    $errorDetails = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $_.Exception.Message }
    $results += @{Test = "Registration"; Status = "FAIL"; Details = $errorDetails }
}

# Test 4: Port connectivity
Write-Host "`n[Test 4/4] Testing port connectivity..." -ForegroundColor Yellow
$ports = @(80, 5000, 27017)
foreach ($port in $ports) {
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($ServerIP, $port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(3000, $false)
        
        if ($wait) {
            $tcpClient.EndConnect($connect)
            Write-Host "  ✅ Port $port is open" -ForegroundColor Green
            $tcpClient.Close()
        }
        else {
            Write-Host "  ❌ Port $port is closed/filtered" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  ❌ Port $port is not accessible" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "DIAGNOSTIC SUMMARY" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$passCount = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count

foreach ($result in $results) {
    $color = if ($result.Status -eq "PASS") { "Green" } else { "Red" }
    $icon = if ($result.Status -eq "PASS") { "✅" } else { "❌" }
    Write-Host "`n$icon $($result.Test): $($result.Status)" -ForegroundColor $color
    Write-Host "   Details: $($result.Details)" -ForegroundColor Gray
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Results: $passCount passed, $failCount failed" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Yellow" })
Write-Host "================================" -ForegroundColor Cyan

# Next steps
if ($failCount -gt 0) {
    Write-Host "`nNEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Check if backend container is running on the server:"
    Write-Host "   ssh azureuser@$ServerIP 'docker ps'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Check backend logs:"
    Write-Host "   ssh azureuser@$ServerIP 'docker logs backend'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Check Network Security Group rules allow ports 80, 5000"  -ForegroundColor Gray
}
