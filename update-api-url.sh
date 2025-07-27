#!/bin/bash

# Update API Gateway URL in the HTML file
# This script updates the API_BASE_URL in password-generator.html with the actual API Gateway URL

set -e

echo "🔧 Updating API Gateway URL in password-generator.html..."

# Get the API Gateway URL from Terraform output
API_URL=$(terraform output -raw api_gateway_url)

if [ -z "$API_URL" ]; then
    echo "❌ Could not retrieve API Gateway URL from Terraform output"
    echo "   Make sure you have run 'terraform apply' first"
    exit 1
fi

echo "📡 API Gateway URL: $API_URL"

# Update the API_BASE_URL in the HTML file
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|const API_BASE_URL = 'https://your-api-gateway-url.amazonaws.com/prod';|const API_BASE_URL = '$API_URL';|g" password-generator.html
else
    # Linux
    sed -i "s|const API_BASE_URL = 'https://your-api-gateway-url.amazonaws.com/prod';|const API_BASE_URL = '$API_URL';|g" password-generator.html
fi

echo "✅ API Gateway URL updated successfully"
echo ""
echo "📝 Next Steps:"
echo "   1. Run './update.sh' to upload the updated HTML file to S3"
echo "   2. Test the password generator with the counter functionality"
echo "" 