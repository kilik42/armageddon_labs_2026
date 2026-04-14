# Primary region for the main infrastructure stack.
variable "aws_region" {
  description = "AWS region for LAB2 infrastructure resources"
  type        = string
  default     = "us-west-2"
}

# Root domain already managed in Route53.
variable "domain_name" {
  description = "Primary hosted zone domain name"
  type        = string
  default     = "tetsuzai-kube.com"
}

# Subdomain that will route through CloudFront.
variable "app_subdomain" {
  description = "CloudFront application subdomain"
  type        = string
  default     = "app"
}

# Existing ALB name from LAB1 used as CloudFront origin.
variable "alb_name" {
  description = "Existing Application Load Balancer name from LAB1"
  type        = string
  default     = "lab1-redone-alb"
}