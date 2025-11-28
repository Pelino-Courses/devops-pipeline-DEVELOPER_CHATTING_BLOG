# Apply Backend Fix Script
# Copies the fixed authController.js and restarts the backend

$serverIP = "51.103.157.72"
$username = "azureuser"
$localFile = "backend/src/controllers/authController.js"
$remoteTmp = "/tmp/authController.js"
$remoteDest = "/opt/devops-app/backend/src/controllers/authController.js"

Write-Host "================================" -ForegroundColor Cyan
# Apply Backend Fix Script
# Copies the fixed authController.js and restarts the backend

$serverIP = "51.103.157.72"
$username = "azureuser"
$localFile = "backend/src/controllers/authController.js"
$remoteTmp = "/tmp/authController.js"
$remoteDest = "/opt/devops-app/backend/src/controllers/authController.js"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Applying Backend Fix" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Step 1: Copy file to server
Write-Host "`n[1/3] Copying authController.js to server..." -ForegroundColor Yellow
try {
    & "C:\Windows\System32\OpenSSH\scp.exe" $localFile ${username}@${serverIP}:${remoteTmp}
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ File copied successfully" -ForegroundColor Green
    }
    else {
        throw "SCP failed"
    }
}
catch {
    Write-Host "❌ Failed to copy file" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Gray
    exit 1
}

# Step 2: Move file and restart backend
Write-Host "`n[2/3] Updating file and restarting backend..." -ForegroundColor Yellow
$commands = "sudo cp $remoteTmp $remoteDest && cd /opt/devops-app && sudo docker-compose restart backend"

try {
    & "C:\Windows\System32\OpenSSH\ssh.exe" ${username}@${serverIP} $commands
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Backend restarted successfully" -ForegroundColor Green
    }
    else {
        throw "SSH command failed"
    }
}
catch {
    Write-Host "❌ Failed to restart backend" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Gray
    exit 1
}

# Step 3: Verify
Write-Host "`n[3/3] Waiting for service to stabilize..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
Write-Host "Checking logs..." -ForegroundColor Gray
& "C:\Windows\System32\OpenSSH\ssh.exe" ${username}@${serverIP} "docker logs --tail 20 backend"

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Fix Applied!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
