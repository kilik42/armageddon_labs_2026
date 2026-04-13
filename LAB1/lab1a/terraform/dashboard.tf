# CloudWatch dashboard for the public-facing application stack.
# I want one place to quickly see traffic, health, errors, and WAF activity without clicking through multiple services.
resource "aws_cloudwatch_dashboard" "lab1_dashboard" {
  dashboard_name = "${local.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title   = "ALB Request Count"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              aws_lb.app_alb.arn_suffix
            ]
          ]
          stat   = "Sum"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title   = "ALB Target Response Time"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              aws_lb.app_alb.arn_suffix
            ]
          ]
          stat   = "Average"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title   = "ALB Healthy / Unhealthy Hosts"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          metrics = [
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "TargetGroup",
              aws_lb_target_group.app_tg.arn_suffix,
              "LoadBalancer",
              aws_lb.app_alb.arn_suffix
            ],
            [
              ".",
              "UnHealthyHostCount",
              ".",
              ".",
              ".",
              "."
            ]
          ]
          stat   = "Average"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title   = "ALB 5XX Errors"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              aws_lb.app_alb.arn_suffix
            ]
          ]
          stat   = "Sum"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          title   = "WAF Allowed Requests"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          metrics = [
            [
              "AWS/WAFV2",
              "AllowedRequests",
              "WebACL",
              aws_wafv2_web_acl.app_waf.name,
              "Region",
              var.aws_region,
              "Rule",
              "ALL"
            ]
          ]
          stat   = "Sum"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          title   = "WAF Blocked Requests"
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          metrics = [
            [
              "AWS/WAFV2",
              "BlockedRequests",
              "WebACL",
              aws_wafv2_web_acl.app_waf.name,
              "Region",
              var.aws_region,
              "Rule",
              "ALL"
            ]
          ]
          stat   = "Sum"
          period = 60
        }
      }
    ]
  })
}