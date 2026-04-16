# AWS region for the logical primary region side of LAB3A.
# This remains us-west-2 in the portfolio adaptation, even though the architecture models Tokyo as the data-authority side.
variable "aws_region" {
  description = "AWS region for the logical primary region side"
  type        = string
  default     = "us-west-2"
}

# Base project name used for naming and tagging resources on the primary-side TGW layer.
variable "project_name" {
  description = "Base name for LAB3 primary-side resources"
  type        = string
  default     = "lab3-tokyo"
}

# Existing primary VPC ID from the LAB1/LAB2 stack.
# This is the VPC that will conceptually represent the Tokyo/data-authority side.
variable "primary_vpc_id" {
  description = "Existing primary VPC ID from LAB1/LAB2"
  type        = string
}