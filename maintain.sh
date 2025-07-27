#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🔧 Password Generator - Maintenance Script${NC}"
echo "=============================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command_exists aws; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

if ! command_exists terraform; then
    echo -e "${RED}❌ Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Check AWS credentials
echo -e "${YELLOW}🔐 Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials found${NC}"

# Check if password-generator.html exists
if [ ! -f "password-generator.html" ]; then
    echo -e "${RED}❌ password-generator.html not found in current directory${NC}"
    exit 1
fi

echo -e "${GREEN}✅ password-generator.html found${NC}"

# Function to get deployment info
get_deployment_info() {
    S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null)
    CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null)
    CLOUDFRONT_URL=$(terraform output -raw cloudfront_url 2>/dev/null)
    
    if [ -z "$S3_BUCKET" ] || [ -z "$CLOUDFRONT_ID" ]; then
        return 1
    fi
    return 0
}

# Check if deployment exists
echo -e "${YELLOW}🔍 Checking existing deployment...${NC}"
if ! get_deployment_info; then
    echo -e "${YELLOW}⚠️  No existing deployment found. Running initial deployment...${NC}"
    echo ""
    
    # Initialize Terraform
    echo -e "${YELLOW}🔧 Initializing Terraform...${NC}"
    terraform init
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Terraform initialization failed${NC}"
        exit 1
    fi
    
    # Apply Terraform configuration
    echo -e "${YELLOW}🏗️  Creating S3 bucket, CloudFront distribution and deploying website...${NC}"
    terraform apply -auto-approve
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Initial deployment failed${NC}"
        exit 1
    fi
    
    # Get deployment info again
    get_deployment_info
fi

echo -e "${GREEN}✅ Existing deployment found${NC}"

# Upload updated files
echo -e "${YELLOW}📤 Uploading updated password-generator.html...${NC}"
aws s3 cp password-generator.html s3://${S3_BUCKET}/password-generator.html \
    --content-type "text/html" \
    --cache-control "no-cache"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to upload password-generator.html${NC}"
    exit 1
fi

echo -e "${GREEN}✅ File uploaded successfully${NC}"

# Create CloudFront invalidation
echo -e "${YELLOW}🔄 Creating CloudFront invalidation...${NC}"
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id ${CLOUDFRONT_ID} \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to create CloudFront invalidation${NC}"
    exit 1
fi

echo -e "${GREEN}✅ CloudFront invalidation created${NC}"

# Success message
echo ""
echo -e "${GREEN}✅ Maintenance completed successfully!${NC}"
echo "=============================================="
echo -e "🪣 S3 Bucket: ${BLUE}${S3_BUCKET}${NC}"
echo -e "🆔 CloudFront Distribution ID: ${BLUE}${CLOUDFRONT_ID}${NC}"
echo -e "🔄 Invalidation ID: ${BLUE}${INVALIDATION_ID}${NC}"
echo -e "🌐 Website URL: ${GREEN}${CLOUDFRONT_URL}${NC}"
echo ""
echo -e "${YELLOW}📝 Notes:${NC}"
echo -e "   • CloudFront invalidation may take 5-10 minutes to complete"
echo -e "   • Your website is now live with Flagsmith integration"
echo -e "   • Test the feature flag by toggling 'copy_function' in Flagsmith dashboard"
echo ""
echo -e "${PURPLE}🎯 Interview Demo Ready!${NC}"
echo -e "   • Open: ${GREEN}${CLOUDFRONT_URL}${NC}"
echo -e "   • Toggle the copy function in Flagsmith dashboard"
echo -e "   • Refresh the page to see real-time changes"
echo ""
echo -e "To run maintenance again: ${BLUE}./maintain.sh${NC}"
echo -e "To destroy all resources: ${RED}terraform destroy${NC}" 