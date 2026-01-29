$ErrorActionPreference = "Stop"

# Configuration
$subscriptionId = "4459723a-46af-46c3-af53-dfb3a134618b"
$resourceGroup = "rgtestenv"
$location = "westus3"
$workspaceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.OperationalInsights/workspaces/log3q5rgs3v7fkls"
$workbookId = [guid]::NewGuid().ToString()

Write-Host "Creating workbook with ID: $workbookId" -ForegroundColor Cyan

# Read workbook template
$workbookTemplatePath = Join-Path $PSScriptRoot "workbook-template.json"
$serializedData = Get-Content $workbookTemplatePath -Raw

# Create request body
$body = @{
    location = $location
    kind = "shared"
    properties = @{
        displayName = "AI Services Observability"
        category = "AI"
        sourceId = $workspaceId
        version = "1.0"
        serializedData = $serializedData
    }
}

$bodyJson = $body | ConvertTo-Json -Depth 10 -Compress

# Get access token
Write-Host "Getting access token..." -ForegroundColor Yellow
$token = az account get-access-token --query accessToken --output tsv

if (-not $token) {
    throw "Failed to get access token"
}

# Deploy workbook
$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Insights/workbooks/$($workbookId)?api-version=2022-04-01"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "Deploying workbook..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $bodyJson
    Write-Host "✓ Workbook deployed successfully!" -ForegroundColor Green
    Write-Host "Workbook Name: $($response.name)" -ForegroundColor Green
    Write-Host "Display Name: $($response.properties.displayName)" -ForegroundColor Green
    Write-Host ""
    Write-Host "View in Azure Portal:" -ForegroundColor Cyan
    Write-Host "https://portal.azure.com/#@/resource/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Insights/workbooks/$workbookId" -ForegroundColor Cyan
}
catch {
    Write-Host "✗ Deployment failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
    exit 1
}
