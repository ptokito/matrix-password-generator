#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${GREEN}🔄 Updating Password Generator${NC}"
echo "================================"

# Check if git is available
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is not installed or not in PATH${NC}"
    exit 1
fi

# Check if this is a git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}⚠️  Not a git repository. Skipping GitHub push.${NC}"
    GIT_AVAILABLE=false
else
    GIT_AVAILABLE=true
    echo -e "${BLUE}📦 Git repository detected${NC}"
fi

# Get the S3 bucket name and CloudFront distribution ID
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null)
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null)

if [ -z "$S3_BUCKET" ] || [ -z "$CLOUDFRONT_ID" ]; then
    echo -e "${RED}❌ Could not find deployment. Run ./deploy.sh first.${NC}"
    exit 1
fi

# Check if password-generator.html exists
if [ ! -f "password-generator.html" ]; then
    echo -e "${RED}❌ password-generator.html not found in current directory${NC}"
    exit 1
fi

# Upload updated password-generator.html to S3
echo -e "${YELLOW}📤 Uploading updated password-generator.html...${NC}"
aws s3 cp password-generator.html s3://${S3_BUCKET}/password-generator.html \
    --content-type "text/html" \
    --cache-control "no-cache"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to upload password-generator.html${NC}"
    exit 1
fi

# Create CloudFront invalidation
echo -e "${YELLOW}🔄 Invalidating CloudFront cache...${NC}"
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id ${CLOUDFRONT_ID} \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to create CloudFront invalidation${NC}"
    exit 1
fi

# GitHub operations
if [ "$GIT_AVAILABLE" = true ]; then
    echo -e "${PURPLE}🐙 GitHub Operations${NC}"
    echo "================================"
    
    # Check if there are changes to commit
    if git diff --quiet; then
        echo -e "${YELLOW}📝 No changes detected in git${NC}"
    else
        echo -e "${YELLOW}📝 Staging changes...${NC}"
        git add .
        
        echo -e "${YELLOW}📝 Committing changes...${NC}"
        git commit -m "Update Matrix Password Generator - $(date '+%Y-%m-%d %H:%M:%S')"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Changes committed successfully${NC}"
            
            # Check if remote exists
            if git remote get-url origin &> /dev/null; then
                echo -e "${YELLOW}🚀 Pushing to GitHub...${NC}"
                git push origin main 2>/dev/null || git push origin master 2>/dev/null
                
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✅ Successfully pushed to GitHub${NC}"
                else
                    echo -e "${RED}❌ Failed to push to GitHub${NC}"
                    echo -e "${YELLOW}💡 Make sure you have the correct permissions and remote is configured${NC}"
                fi
            else
                echo -e "${YELLOW}⚠️  No remote 'origin' found. Skipping push.${NC}"
                echo -e "${BLUE}💡 To add a remote: git remote add origin <your-repo-url>${NC}"
            fi
        else
            echo -e "${RED}❌ Failed to commit changes${NC}"
        fi
    fi
fi

# Get the CloudFront URL
CLOUDFRONT_URL=$(terraform output -raw cloudfront_url 2>/dev/null)

echo -e "${GREEN}✅ Update completed successfully!${NC}"
echo "================================"
echo -e "🪣 S3 Bucket: ${BLUE}${S3_BUCKET}${NC}"
echo -e "🆔 CloudFront Distribution ID: ${BLUE}${CLOUDFRONT_ID}${NC}"
echo -e "🔄 Invalidation ID: ${BLUE}${INVALIDATION_ID}${NC}"
if [ ! -z "$CLOUDFRONT_URL" ]; then
    echo -e "🌐 Website URL: ${GREEN}${CLOUDFRONT_URL}${NC}"
fi
echo ""
echo -e "${YELLOW}📝 Note: Cache invalidation may take 5-10 minutes to complete${NC}"
