# Apply Backend Fixes using Azure CLI
# This script uses 'az vm run-command' to execute the fix script on the VM
# This avoids the need for SCP or SSH in PowerShell

$resourceGroup = "devopspipeline-dev-rg"
$vmName = "devopspipeline-dev-vm"
$scriptPath = "deploy_fix.sh"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Applying Backend Fixes via Azure CLI" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Error: $scriptPath not found!" -ForegroundColor Red
    exit 1
}

Write-Host "[1/2] Checking Azure CLI login..." -ForegroundColor Yellow
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
}
catch {
    Write-Host "❌ Not logged in to Azure CLI. Please run 'az login'." -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/2] Sending and executing fix script on VM..." -ForegroundColor Yellow
Write-Host "   Target: $vmName (Resource Group: $resourceGroup)" -ForegroundColor Gray
Write-Host "   This may take a minute or two..." -ForegroundColor Gray

# Use az vm run-command to execute the local script
# We use @script.sh syntax to pass the file content
try {
    az vm run-command invoke `
        --command-id RunShellScript `
        --name $vmName `
        --resource-group $resourceGroup `
        --scripts "@$scriptPath" 

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Fix script executed successfully!" -ForegroundColor Green
        Write-Host "   The backend should be restarting now." -ForegroundColor Gray
    }
    else {
        throw "Azure CLI command failed"
    }
}
catch {
    Write-Host "`n❌ Failed to execute script on VM" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Verification" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Please wait 30 seconds for the backend to start, then run:" -ForegroundColor Yellow
Write-Host "   .\diagnose_deployed_backend.ps1" -ForegroundColor White
