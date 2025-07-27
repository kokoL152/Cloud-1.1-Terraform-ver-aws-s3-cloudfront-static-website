
terraform {
  required_version = ">= 1.0.0" #  Terraform version

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # AWS Provider version
    }
  }
}

provider "aws" {
  region = var.aws_region # get version from variables.tf 
}
