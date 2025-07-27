
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "${var.bucket_name_prefix}-${random_string.bucket_suffix.result}"
  # bucket_prefix = var.bucket_name_prefix # if want to use bucket_prefix
  # bucket = "${var.bucket_name_prefix}-${random_id.random.hex}" #another generation way

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags = {
    Project = "StaticWebsiteDeployment"
    ManagedBy = "Terraform"
  }
}

# aws S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "website_bucket_public_access_block" {
  bucket = aws_s3_bucket.website_bucket.id

  #  false = allow public access 
  block_public_acls       = false 
  block_public_policy     = false # allow bucket policy 
  ignore_public_acls      = false 
  restrict_public_buckets = false 
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.website_bucket.arn}/*"
        ]
      },
    ]
  })
  depends_on = [
    aws_s3_bucket_public_access_block.website_bucket_public_access_block,
  ]
}

# Upload website content to S3
resource "aws_s3_bucket_object" "index_html" {
  bucket = aws_s3_bucket.website_bucket.id
  key    = "index.html"
  source = "${var.website_content_path}/index.html"
  content_type = "text/html"
  etag = filemd5("${var.website_content_path}/index.html")
}

resource "aws_s3_bucket_object" "error_html" {
  bucket = aws_s3_bucket.website_bucket.id
  key    = "error.html"
  source = "${var.website_content_path}/error.html"
  content_type = "text/html"
  etag = filemd5("${var.website_content_path}/error.html")
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.website_bucket.id

    s3_origin_config{
     origin_access_identity = "" 
    }
    # origin_access_control_id = aws_cloudfront_origin_access_control.default.id # If using OAC
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for static S3 website"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.website_bucket.id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https" # Redirect HTTP to HTTPS
    min_ttl                = 0
    default_ttl            = 3600 # cache 1h
    max_ttl                = 86400 # cache 24h
  }

  # Custom error pages for 404
  custom_error_response {
    error_code         = 404
    response_page_path = "/error.html"
    response_code      = 200 # return 200，but show 404 page
    error_caching_min_ttl = 300 # cache 5mins
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" 
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # Use CloudFront default SSL certificate
  }

  tags = {
    Project = "StaticWebsiteDeployment"
    ManagedBy = "Terraform"
  }
}
