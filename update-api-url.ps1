# Update API Gateway URL in the HTML file (Windows PowerShell)
# This script updates the API_BASE_URL in password-generator.html with the actual API Gateway URL

$ErrorActionPreference = "Stop"

Write-Host "🔧 Updating API Gateway URL in password-generator.html..." -ForegroundColor Yellow

# Get the API Gateway URL from Terraform output
$API_URL = terraform output -raw api_gateway_url

if (-not $API_URL) {
    Write-Host "❌ Could not retrieve API Gateway URL from Terraform output" -ForegroundColor Red
    Write-Host "   Make sure you have run 'terraform apply' first" -ForegroundColor Red
    exit 1
}

Write-Host "📡 API Gateway URL: $API_URL" -ForegroundColor Cyan

# Update the API_BASE_URL in the HTML file
try {
    $content = Get-Content "password-generator.html" -Raw
    $updatedContent = $content -replace "const API_BASE_URL = 'https://your-api-gateway-url\.amazonaws\.com/prod';", "const API_BASE_URL = '$API_URL';"
    Set-Content "password-generator.html" $updatedContent -NoNewline
    
    Write-Host "✅ API Gateway URL updated successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to update API Gateway URL. Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Run './update.sh' to upload the updated HTML file to S3" -ForegroundColor White
Write-Host "   2. Test the password generator with the counter functionality" -ForegroundColor White
Write-Host "" 