terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Random string for unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# DynamoDB table for password counter
resource "aws_dynamodb_table" "password_counter" {
  name           = "password-generator-counter"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "password-generator-counter"
    Environment = "demo"
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "password-generator-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda to access DynamoDB
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "lambda-dynamodb-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.password_counter.arn
      }
    ]
  })
}

# IAM policy for Lambda CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create deployment package for Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function_simple.py"
  output_path = "lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "password_counter" {
  filename         = "lambda_function.zip"
  function_name    = "password-generator-counter"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.password_counter.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy.lambda_dynamodb_policy
  ]
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "password_api" {
  name        = "password-generator-api"
  description = "API for password generator counter"
}

# API Gateway resource
resource "aws_api_gateway_resource" "counter" {
  rest_api_id = aws_api_gateway_rest_api.password_api.id
  parent_id   = aws_api_gateway_rest_api.password_api.root_resource_id
  path_part   = "counter"
}

# API Gateway method for GET
resource "aws_api_gateway_method" "get_counter" {
  rest_api_id   = aws_api_gateway_rest_api.password_api.id
  resource_id   = aws_api_gateway_resource.counter.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway method for POST
resource "aws_api_gateway_method" "post_counter" {
  rest_api_id   = aws_api_gateway_rest_api.password_api.id
  resource_id   = aws_api_gateway_resource.counter.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway method for OPTIONS (CORS)
resource "aws_api_gateway_method" "options_counter" {
  rest_api_id   = aws_api_gateway_rest_api.password_api.id
  resource_id   = aws_api_gateway_resource.counter.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# API Gateway integration for GET
resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id = aws_api_gateway_rest_api.password_api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.get_counter.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.password_counter.invoke_arn
}

# API Gateway integration for POST
resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id = aws_api_gateway_rest_api.password_api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.post_counter.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.password_counter.invoke_arn
}

# API Gateway integration for OPTIONS
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.password_api.id
  resource_id = aws_api_gateway_resource.counter.id
  http_method = aws_api_gateway_method.options_counter.http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Note: Method responses are not needed for AWS_PROXY integrations
# The Lambda function handles all response formatting

# Note: Integration responses are not needed for AWS_PROXY integrations
# The Lambda function handles CORS headers directly

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.password_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.password_api.execution_arn}/*/*"
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.get_integration,
    aws_api_gateway_integration.post_integration,
    aws_api_gateway_integration.options_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.password_api.id
  stage_name  = "prod"
}

# S3 bucket for static website hosting
resource "aws_s3_bucket" "website" {
  bucket = "password-generator-demo-${random_string.bucket_suffix.result}"
}

# S3 bucket public access block (allowing public access for static website)
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "password-generator.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 bucket policy for public read access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# Upload password-generator.html
resource "aws_s3_object" "password_generator" {
  bucket       = aws_s3_bucket.website.id
  key          = "password-generator.html"
  source       = "password-generator.html"
  content_type = "text/html"
  etag         = filemd5("password-generator.html")
}

# Upload robots.txt
resource "aws_s3_object" "robots_txt" {
  bucket       = aws_s3_bucket.website.id
  key          = "robots.txt"
  source       = "robots.txt"
  content_type = "text/plain"
  etag         = filemd5("robots.txt")
}

# Upload sitemap.xml
resource "aws_s3_object" "sitemap_xml" {
  bucket       = aws_s3_bucket.website.id
  key          = "sitemap.xml"
  source       = "sitemap.xml"
  content_type = "application/xml"
  etag         = filemd5("sitemap.xml")
}

# Upload site.webmanifest
resource "aws_s3_object" "webmanifest" {
  bucket       = aws_s3_bucket.website.id
  key          = "site.webmanifest"
  source       = "site.webmanifest"
  content_type = "application/manifest+json"
  etag         = filemd5("site.webmanifest")
}

# Create a simple error page
resource "aws_s3_object" "error_page" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  content      = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Page Not Found</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #333; }
        a { color: #007bff; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>404 - Page Not Found</h1>
    <p>The page you're looking for doesn't exist.</p>
    <a href="password-generator.html">Go to Password Generator</a>
</body>
</html>
EOF
  content_type = "text/html"
}

# CloudFront distribution for secure, fast delivery
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "password-generator.html"
  price_class         = "PriceClass_100" # Use only North America and Europe

  origin {
    domain_name = aws_s3_bucket_website_configuration.website.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.website.id}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.website.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600    # 1 hour
    max_ttl     = 86400   # 24 hours
  }

  # Cache behavior for HTML files
  ordered_cache_behavior {
    path_pattern     = "*.html"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0      # No caching for HTML files
    max_ttl                = 0
  }

  # Cache behavior for CSS and JS files
  ordered_cache_behavior {
    path_pattern     = "*.css"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.website.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400   # 24 hours
    max_ttl                = 31536000 # 1 year
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code         = 404
    response_code      = "200"
    response_page_path = "/error.html"
  }
}

# Outputs
output "s3_bucket_name" {
  value       = aws_s3_bucket.website.id
  description = "Name of the S3 bucket"
}

output "s3_website_url" {
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
  description = "S3 website URL (direct access)"
}

output "cloudfront_url" {
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
  description = "CloudFront distribution URL (recommended)"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.website.id
  description = "CloudFront distribution ID"
}

output "api_gateway_url" {
  value       = "${aws_api_gateway_deployment.deployment.invoke_url}/counter"
  description = "API Gateway URL for counter endpoint"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.password_counter.name
  description = "DynamoDB table name for password counter"
}
