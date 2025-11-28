# Open Port 5000 in Azure NSG for Backend Access
# This script adds a Network Security Group rule to allow backend traffic

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Opening Port 5000 in Azure NSG" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Configuration - these match your Terraform setup
$resourceGroup = "devopspipeline-dev-rg"
$nsgName = "devopspipeline-dev-nsg"
$ruleName = "Allow-Backend-5000"

Write-Host "[1/4] Checking Azure CLI login..." -ForegroundColor Yellow
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "   Subscription: $($account.name)" -ForegroundColor Gray
}
catch {
    Write-Host "❌ Not logged in to Azure CLI" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please login first:" -ForegroundColor Yellow
    Write-Host "   az login" -ForegroundColor Gray
    exit 1
}

Write-Host "`n[2/4] Checking if NSG exists..." -ForegroundColor Yellow
try {
    $nsg = az network nsg show --resource-group $resourceGroup --name $nsgName 2>&1 | ConvertFrom-Json
    Write-Host "✅ Found NSG: $nsgName" -ForegroundColor Green
}
catch {
    Write-Host "❌ NSG not found: $nsgName" -ForegroundColor Red
    Write-Host "   Resource Group: $resourceGroup" -ForegroundColor Gray
    exit 1
}

Write-Host "`n[3/4] Checking if rule already exists..." -ForegroundColor Yellow
$existingRule = az network nsg rule show --resource-group $resourceGroup --nsg-name $nsgName --name $ruleName 2>$null
if ($existingRule) {
    Write-Host "⚠️  Rule '$ruleName' already exists" -ForegroundColor Yellow
    $response = Read-Host "Do you want to update it? (y/n)"
    if ($response -ne 'y') {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
    Write-Host "Deleting existing rule..." -ForegroundColor Yellow
    az network nsg rule delete --resource-group $resourceGroup --nsg-name $nsgName --name $ruleName | Out-Null
}

Write-Host "`n[4/4] Creating NSG rule to allow port 5000..." -ForegroundColor Yellow
try {
    az network nsg rule create `
        --resource-group $resourceGroup `
        --nsg-name $nsgName `
        --name $ruleName `
        --priority 140 `
        --direction Inbound `
        --access Allow `
        --protocol Tcp `
        --source-port-range '*' `
        --destination-port-range 5000 `
        --source-address-prefix '*' `
        --destination-address-prefix '*' `
        --description "Allow backend API traffic on port 5000" | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ NSG rule created successfully!" -ForegroundColor Green
    }
    else {
        throw "Failed to create NSG rule"
    }
}
catch {
    Write-Host "❌ Failed to create NSG rule" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Port 5000 is now open!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testing backend connectivity..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Test if backend is now accessible
try {
    $response = Invoke-WebRequest -Uri "http://51.103.157.72:5000/health" -TimeoutSec 10 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Backend /health endpoint is now accessible!" -ForegroundColor Green
        Write-Host "   Response: $($response.Content)" -ForegroundColor Gray
    }
}
catch {
    Write-Host "⚠️  Backend not responding yet" -ForegroundColor Yellow
    Write-Host "   This might mean the backend container isn't running" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. SSH to the server and check if containers are running:"
    Write-Host "   ssh azureuser@51.103.157.72 'docker ps'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Check backend logs:"
    Write-Host "   ssh azureuser@51.103.157.72 'docker logs backend'" -ForegroundColor Gray
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "You can now test registration/login from your frontend!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan
