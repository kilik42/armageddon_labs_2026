terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider for the logical primary region side of LAB3A.
# In this portfolio adaptation, the existing us-west-2 stack is treated as the Tokyo/data-authority side.
provider "aws" {
  region = var.aws_region
}