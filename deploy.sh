#!/bin/bash

# Password Generator Demo - Full Deployment Script
# This script deploys the complete infrastructure including the new API backend

set -e

echo "🚀 Starting Password Generator Demo Deployment..."

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

# Create Lambda deployment package
echo "📦 Creating Lambda deployment package..."
if [ -f "lambda_function.zip" ]; then
    rm lambda_function.zip
fi

# Create a temporary directory for Lambda packaging
mkdir -p lambda_package
cp lambda_function.py lambda_package/
cp requirements.txt lambda_package/

# Install dependencies in the package directory
cd lambda_package

# Try different pip commands for different systems
if command -v pip3 &> /dev/null; then
    pip3 install -r requirements.txt -t .
elif command -v pip &> /dev/null; then
    pip install -r requirements.txt -t .
elif python -m pip --version &> /dev/null; then
    python -m pip install -r requirements.txt -t .
elif python3 -m pip --version &> /dev/null; then
    python3 -m pip install -r requirements.txt -t .
else
    echo "❌ No pip installation found. Please install Python and pip first."
    exit 1
fi

rm requirements.txt

# Create the ZIP file
zip -r ../lambda_function.zip .
cd ..
rm -rf lambda_package

echo "✅ Lambda package created"

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
echo "   • Lambda function handles counter operations"
echo ""
