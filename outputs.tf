# outputs.tf

output "s3_website_endpoint" {
  description = "The S3 static website endpoint"
  value       = aws_s3_bucket.website_bucket.website_endpoint
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}
