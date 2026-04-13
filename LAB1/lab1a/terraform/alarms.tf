# CloudWatch alarm that triggers when the ALB target group reports unhealthy hosts.
# This gives me a basic operational signal that the application is no longer serving traffic correctly.
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${local.project_name}-alb-unhealthy-hosts"
  alarm_description   = "Triggers when the application target group has unhealthy hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"
  statistic   = "Average"
  period      = 60

  # These dimensions tie the alarm directly to this lab's ALB and target group.
  # If the app instance fails health checks, this metric should go above zero.
  dimensions = {
    TargetGroup  = aws_lb_target_group.app_tg.arn_suffix
    LoadBalancer = aws_lb.app_alb.arn_suffix
  }

  # Send an alert when the alarm enters ALARM state.
  alarm_actions = [
    aws_sns_topic.ops_alerts.arn
  ]

  # Also notify when the system returns to OK.
  ok_actions = [
    aws_sns_topic.ops_alerts.arn
  ]

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-alb-unhealthy-hosts"
  })
}