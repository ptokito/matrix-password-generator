#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🔄 CloudFront Cache Invalidation${NC}"
echo "================================"

# Get CloudFront distribution ID
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null)

if [ -z "$CLOUDFRONT_ID" ]; then
    echo -e "${RED}❌ Could not find CloudFront distribution. Run ./maintain.sh first.${NC}"
    exit 1
fi

echo -e "${YELLOW}📤 Creating CloudFront invalidation...${NC}"
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id ${CLOUDFRONT_ID} \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to create CloudFront invalidation${NC}"
    exit 1
fi

echo -e "${GREEN}✅ CloudFront invalidation created successfully!${NC}"
echo "================================"
echo -e "🆔 Distribution ID: ${BLUE}${CLOUDFRONT_ID}${NC}"
echo -e "🔄 Invalidation ID: ${BLUE}${INVALIDATION_ID}${NC}"
echo ""
echo -e "${YELLOW}📝 Note: Invalidation may take 5-10 minutes to complete${NC}" 