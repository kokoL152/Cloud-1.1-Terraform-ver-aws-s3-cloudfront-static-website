
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-northeast-1" # change to your region
}

variable "bucket_name_prefix" {
  description = "A unique prefix for the S3 bucket name"
  type        = string
  default     = "my-tf-static-website" # insert an unique name
}

variable "website_content_path" {
  description = "Path to the local website content directory"
  type        = string
  default     = "./website" # insert the path towards your website
}
