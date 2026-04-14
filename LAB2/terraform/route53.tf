# CloudFront distribution in front of the existing LAB1 ALB.
# This is the main LAB2 upgrade: users hit CloudFront first, and CloudFront forwards to the ALB origin.
resource "aws_cloudfront_distribution" "app_cdn" {
  enabled             = true # CloudFront distributions are disabled by default, so we need to explicitly enable it.
  is_ipv6_enabled     = true # Enable IPv6 support for modern clients.
  comment             = "LAB2 CloudFront distribution for app.tetsuzai-kube.com"
  default_root_object = ""

  aliases = [
    "${var.app_subdomain}.${var.domain_name}"
  ]

  origin {
    domain_name = data.aws_lb.lab1_alb.dns_name # Use the existing ALB from LAB1 as the origin for CloudFront.
    origin_id   = "lab1-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # CloudFront will use HTTP to communicate with the origin. The ALB will handle redirecting to HTTPS if needed.
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default behavior handles dynamic/app traffic.
  # This path should not be cached aggressively because requests like /list or /add can change.
  default_cache_behavior {
    target_origin_id       = "lab1-alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.dynamic_no_cache_policy.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.dynamic_origin_request_policy.id
  }

  # Static content behavior.
  # If static files are served from /static/*, CloudFront can cache them much more aggressively.
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "lab1-alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id            = aws_cloudfront_cache_policy.static_cache_policy.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.static_origin_request_policy.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.static_response_headers_policy.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront_cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "${var.app_subdomain}.${var.domain_name}"
    Lab  = "lab2"
  }
}

# Route53 alias record for the CloudFront distribution.
# This makes app.tetsuzai-kube.com resolve to CloudFront instead of directly to the ALB.
resource "aws_route53_record" "app_alias" {
  allow_overwrite = true

  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.app_cdn.domain_name
    zone_id                = aws_cloudfront_distribution.app_cdn.hosted_zone_id
    evaluate_target_health = false
  }
}