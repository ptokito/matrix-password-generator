#!/bin/bash

# Password Generator Demo - No-Zip Deployment Script
# This script deploys the complete infrastructure without requiring zip command

set -e

echo "🚀 Starting Password Generator Demo Deployment (No-Zip)..."

# Check if required tools are installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform first."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Create simple Lambda deployment package (no external dependencies)
echo "📦 Creating Lambda deployment package..."
if [ -f "lambda_function.zip" ]; then
    rm lambda_function.zip
fi

# Try different methods to create ZIP file
if command -v python3 &> /dev/null; then
    echo "Using Python to create ZIP file..."
    python3 -c "
import zipfile
with zipfile.ZipFile('lambda_function.zip', 'w') as zipf:
    zipf.write('lambda_function_simple.py')
"
elif command -v python &> /dev/null; then
    echo "Using Python to create ZIP file..."
    python -c "
import zipfile
with zipfile.ZipFile('lambda_function.zip', 'w') as zipf:
    zipf.write('lambda_function_simple.py')
"
elif command -v jar &> /dev/null; then
    echo "Using Java jar to create ZIP file..."
    jar -cf lambda_function.zip lambda_function_simple.py
else
    echo "❌ No suitable tool found to create ZIP file."
    echo "Please install one of: zip, python3, python, or java"
    exit 1
fi

echo "✅ Lambda package created (using built-in AWS SDK)"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan the deployment
echo "📋 Planning Terraform deployment..."
terraform plan -out=tfplan

# Apply the deployment
echo "🚀 Applying Terraform deployment..."
terraform apply tfplan

# Clean up the plan file
rm tfplan

# Get the API Gateway URL
API_URL=$(terraform output -raw api_gateway_url)
CLOUDFRONT_URL=$(terraform output -raw cloudfront_url)

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📊 Deployment Summary:"
echo "   • CloudFront URL: $CLOUDFRONT_URL"
echo "   • API Gateway URL: $API_URL"
echo ""
echo "🔧 Next Steps:"
echo "   1. Update the API_BASE_URL in password-generator.html with: $API_URL"
echo "   2. Run './update.sh' to upload the updated HTML file"
echo "   3. Test the password generator at: $CLOUDFRONT_URL"
echo ""
echo "📝 Notes:"
echo "   • The password counter will be stored in DynamoDB"
echo "   • API Gateway provides CORS support for web requests"
echo "   • Lambda function uses built-in AWS SDK (no external dependencies)"
echo "" 