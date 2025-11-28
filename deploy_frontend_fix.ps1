# Deploy Frontend Fix Script
# Copies fixed JS files to the running frontend container

$serverIP = "51.103.157.72"
$username = "azureuser"
$localApi = "frontend/js/api.js"
$localAuth = "frontend/js/auth.js"
$remoteApi = "/tmp/api.js"
$remoteAuth = "/tmp/auth.js"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Deploying Frontend Fix" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Step 1: Copy files to server
Write-Host "`n[1/3] Copying files to server..." -ForegroundColor Yellow
try {
    & "C:\Windows\System32\OpenSSH\scp.exe" $localApi ${username}@${serverIP}:${remoteApi}
    & "C:\Windows\System32\OpenSSH\scp.exe" $localAuth ${username}@${serverIP}:${remoteAuth}
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Files copied successfully" -ForegroundColor Green
    }
    else {
        throw "SCP failed"
    }
}
catch {
    Write-Host "❌ Failed to copy files" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Gray
    exit 1
}

# Step 2: Update files in container
Write-Host "`n[2/3] Updating files in frontend container..." -ForegroundColor Yellow
$commands = "sudo docker cp $remoteApi frontend:/usr/share/nginx/html/js/api.js && sudo docker cp $remoteAuth frontend:/usr/share/nginx/html/js/auth.js"

try {
    & "C:\Windows\System32\OpenSSH\ssh.exe" ${username}@${serverIP} $commands
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Container updated successfully" -ForegroundColor Green
    }
    else {
        throw "SSH command failed"
    }
}
catch {
    Write-Host "❌ Failed to update container" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Gray
    exit 1
}

# Step 3: Verify
Write-Host "`n[3/3] Verifying update..." -ForegroundColor Yellow
& "C:\Windows\System32\OpenSSH\ssh.exe" ${username}@${serverIP} "docker exec frontend cat /usr/share/nginx/html/js/api.js | grep API_URL"

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Frontend Fix Deployed!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
