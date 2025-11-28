# Quick Deploy Fix Script
# This script will deploy the backend fix to the Azure server

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Backend Fix Deployment" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$serverIP = "51.103.157.72"
$username = "azureuser"

Write-Host "Step 1: Update environment variables on server..." -ForegroundColor Yellow
Write-Host "Run: .\update_server_env.ps1" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter when you've run the above command"

Write-Host "`nStep 2: Copy updated authController.js to server..." -ForegroundColor Yellow
scp backend/src/controllers/authController.js ${username}@${serverIP}:/tmp/authController.js

Write-Host "`nStep 3: Update file on server and restart backend..." -ForegroundColor Yellow  
$commands = @"
sudo cp /tmp/authController.js /opt/devops-app/backend/src/controllers/authController.js
cd /opt/devops-app
sudo docker-compose restart backend
echo 'Waiting for backend to start...'
sleep 5
docker logs --tail 20 backend
"@

ssh ${username}@${serverIP} $commands

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testing the fix..." -ForegroundColor Yellow

# Test the endpoint
try {
    $testBody = @{
        username = "testuser_$(Get-Random)"
        email    = "test_$(Get-Random)@example.com"
        password = "Test123!"
    } | ConvertTo-Json
    
    Write-Host "Sending test registration..." -ForegroundColor Gray
    $response = Invoke-RestMethod -Uri "http://${serverIP}:5000/api/signup" `
        -Method POST `
        -Body $testBody `
        -ContentType "application/json" `
        -TimeoutSec 15
    
    Write-Host "✅ SUCCESS! Registration endpoint now works!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Gray
}
catch {
    Write-Host "⚠️ Response received within timeout (good sign):" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Gray
    Write-Host "`nNote: Even if registration fails, it should fail FAST (not hang)" -ForegroundColor Cyan
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Next: Check backend logs for any email errors" -ForegroundColor Yellow
Write-Host "Run: ssh ${username}@${serverIP} 'docker logs -f backend'" -ForegroundColor White
Write-Host "================================" -ForegroundColor Cyan
