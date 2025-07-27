# Password Generator Demo - Windows PowerShell Deployment Script
# This script deploys the complete infrastructure without requiring Python/pip

# Stop on any error
$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Password Generator Demo Deployment (Windows)..." -ForegroundColor Green

# Check if required tools are installed
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Terraform is not installed. Please install Terraform first." -ForegroundColor Red
    exit 1
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "❌ AWS CLI is not installed. Please install AWS CLI first." -ForegroundColor Red
    exit 1
}

# Check AWS credentials
try {
    aws sts get-caller-identity | Out-Null
} catch {
    Write-Host "❌ AWS credentials not configured. Please run 'aws configure' first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Prerequisites check passed" -ForegroundColor Green

# Create simple Lambda deployment package (no external dependencies)
Write-Host "📦 Creating Lambda deployment package..." -ForegroundColor Yellow
if (Test-Path "lambda_function.zip") {
    Remove-Item "lambda_function.zip"
}

# Create a simple ZIP file with just the Lambda function using PowerShell
try {
    Compress-Archive -Path "lambda_function_simple.py" -DestinationPath "lambda_function.zip" -Force
    Write-Host "✅ Lambda package created (using built-in AWS SDK)" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create Lambda package. Error: $_" -ForegroundColor Red
    exit 1
}

# Initialize Terraform
Write-Host "🔧 Initializing Terraform..." -ForegroundColor Yellow
terraform init

# Plan the deployment
Write-Host "📋 Planning Terraform deployment..." -ForegroundColor Yellow
terraform plan -out=tfplan

# Apply the deployment
Write-Host "🚀 Applying Terraform deployment..." -ForegroundColor Yellow
terraform apply tfplan

# Clean up the plan file
Remove-Item "tfplan" -ErrorAction SilentlyContinue

# Get the API Gateway URL
$API_URL = terraform output -raw api_gateway_url
$CLOUDFRONT_URL = terraform output -raw cloudfront_url

Write-Host ""
Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Deployment Summary:" -ForegroundColor Cyan
Write-Host "   • CloudFront URL: $CLOUDFRONT_URL" -ForegroundColor White
Write-Host "   • API Gateway URL: $API_URL" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Update the API_BASE_URL in password-generator.html with: $API_URL" -ForegroundColor White
Write-Host "   2. Run './update.sh' to upload the updated HTML file" -ForegroundColor White
Write-Host "   3. Test the password generator at: $CLOUDFRONT_URL" -ForegroundColor White
Write-Host ""
Write-Host "📝 Notes:" -ForegroundColor Cyan
Write-Host "   • The password counter will be stored in DynamoDB" -ForegroundColor White
Write-Host "   • API Gateway provides CORS support for web requests" -ForegroundColor White
Write-Host "   • Lambda function uses built-in AWS SDK (no external dependencies)" -ForegroundColor White
Write-Host "" 