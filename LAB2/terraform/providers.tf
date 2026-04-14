terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Primary AWS provider for the main lab infrastructure.
# Most LAB2 resources will remain in the same region as the ALB.
provider "aws" {
  region = var.aws_region
}

# Secondary provider used specifically for ACM certificates for CloudFront.
# AWS requires CloudFront certificates to exist in us-east-1. Weird 
provider "aws" {
  alias  = "east"
  region = "us-east-1"
}