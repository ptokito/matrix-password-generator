#!/bin/bash

# Update SEO URLs in all files
# This script updates all placeholder URLs with the actual CloudFront URL

set -e

echo "🔧 Updating SEO URLs in all files..."

# Get the CloudFront URL from Terraform output
CLOUDFRONT_URL=$(terraform output -raw cloudfront_url)

if [ -z "$CLOUDFRONT_URL" ]; then
    echo "❌ Could not retrieve CloudFront URL from Terraform output"
    echo "   Make sure you have run 'terraform apply' first"
    exit 1
fi

echo "📡 CloudFront URL: $CLOUDFRONT_URL"

# Update robots.txt
echo "Updating robots.txt..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|https://your-cloudfront-url\.cloudfront\.net|$CLOUDFRONT_URL|g" robots.txt
else
    # Linux
    sed -i "s|https://your-cloudfront-url\.cloudfront\.net|$CLOUDFRONT_URL|g" robots.txt
fi

# Update sitemap.xml
echo "Updating sitemap.xml..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|https://your-cloudfront-url\.cloudfront\.net|$CLOUDFRONT_URL|g" sitemap.xml
else
    # Linux
    sed -i "s|https://your-cloudfront-url\.cloudfront\.net|$CLOUDFRONT_URL|g" sitemap.xml
fi

# Update password-generator.html
echo "Updating password-generator.html..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|https://your-cloudfront-url\.cloudfront\.net|$CLOUDFRONT_URL|g" password-generator.html
else
    # Linux
    sed -i "s|https://your-cloudfront-url\.cloudfront\.net|$CLOUDFRONT_URL|g" password-generator.html
fi

echo "✅ SEO URLs updated successfully"
echo ""
echo "📝 Next Steps:"
echo "   1. Update Google Analytics ID in password-generator.html"
echo "   2. Update Google AdSense Publisher ID in password-generator.html"
echo "   3. Run './update.sh' to upload all updated files to S3"
echo ""
echo "🔧 Manual Updates Needed:"
echo "   • Replace 'GA_MEASUREMENT_ID' with your Google Analytics ID"
echo "   • Replace 'ca-pub-YOUR_PUBLISHER_ID' with your AdSense Publisher ID"
echo "   • Replace 'YOUR_AD_SLOT_ID' with your AdSense Ad Slot ID"
echo "" 