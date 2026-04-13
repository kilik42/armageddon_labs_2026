# Regional WAF Web ACL for the application load balancer.
# I am attaching this to the ALB so the public entry point has a basic layer of web request filtering.
resource "aws_wafv2_web_acl" "app_waf" {
  name  = "${local.project_name}-waf"
  scope = "REGIONAL"

  description = "Basic WAF protection for the Lab 1 application ALB"

  default_action {
    allow {} #requests are allowed unless a rule blocks them
  }

  # This managed rule group gives me a solid baseline of common protections
  # without having to build custom WAF rules from scratch.
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {} # I want the default behavior of the managed rule group, which is to block requests that match the rules and allow requests that don't match.
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet" # This is the name of the managed rule group I want to use. It includes protections against common web exploits like SQL injection and cross-site scripting.
      }
    }

    visibility_config {
      # Enabling CloudWatch metrics for this rule allows me to monitor how many requests are being blocked by the managed rule group, which can give me insights into potential attack patterns or false positives.
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.project_name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.project_name}-waf"
    sampled_requests_enabled   = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-waf"
  })
}

# Associate the WAF Web ACL with the ALB.
# This makes the WAF part of the live ingress path instead of just existing as a standalone resource.
resource "aws_wafv2_web_acl_association" "app_waf_assoc" {
  resource_arn = aws_lb.app_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.app_waf.arn
}