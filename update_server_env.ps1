# Update Server Environment Variables
# This script updates the .env file on the Azure VM with the correct credentials
# and restarts the backend service.

$resourceGroup = "devopspipeline-dev-rg"
$vmName = "devopspipeline-dev-vm"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Updating Server Environment Variables" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Checking Azure CLI login..." -ForegroundColor Yellow
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Not logged in to Azure CLI. Please run 'az login'." -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/3] Updating .env file on server..." -ForegroundColor Yellow
Write-Host "   Target: $vmName" -ForegroundColor Gray

# Define the .env content
$envContent = @"
PORT=5000
MONGO_URI=mongodb://mongodb:27017/chatapp
JWT_SECRET=c8f4b8c783067a069252fab01c4e4911a6c2f94116f9bd80921b672bd60311a3
EMAIL_USER=bananezaromeo@gmail.com
EMAIL_PASS=rthtwbcmsgfvqwsb
OTP_EXPIRATION=300000
"@

# Create a temporary script file to run on the VM
$scriptContent = @"
echo "$envContent" | sudo tee /opt/devops-app/.env > /dev/null
cd /opt/devops-app
sudo docker-compose restart backend
"@

# Use az vm run-command to execute the script
try {
    az vm run-command invoke `
        --command-id RunShellScript `
        --name $vmName `
        --resource-group $resourceGroup `
        --scripts "$scriptContent"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Environment variables updated successfully!" -ForegroundColor Green
    }
    else {
        throw "Azure CLI command failed"
    }
}
catch {
    Write-Host "`n❌ Failed to update .env file" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "`n[3/3] Verifying backend restart..." -ForegroundColor Yellow
Write-Host "   Waiting 10 seconds for service to stabilize..." -ForegroundColor Gray
Start-Sleep -Seconds 10

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Update Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Now run the diagnostic script to verify registration:" -ForegroundColor Yellow
Write-Host "   .\diagnose_deployed_backend.ps1" -ForegroundColor White
