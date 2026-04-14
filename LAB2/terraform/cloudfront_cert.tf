#cloudfront_cert.tf 
# Look up the existing public hosted zone for the domain.
# LAB2 reuses the same Route53 zone from LAB1 instead of creating a new one.
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Look up the existing ALB from LAB1.
# CloudFront will use this ALB as the origin instead of creating a brand-new backend path.
data "aws_lb" "lab1_alb" {
  name = var.alb_name
}

# ACM certificate for the CloudFront distribution.
# This must be created in us-east-1 because CloudFront only supports ACM certs from that region.
resource "aws_acm_certificate" "cloudfront_cert" {
  provider          = aws.east
  domain_name       = "${var.app_subdomain}.${var.domain_name}" # in other words, app.tetsuzai-kube.com
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.app_subdomain}.${var.domain_name}" # in other words, app.tetsuzai-kube.com
    Lab  = "lab2"
  }
}

# DNS validation record for the CloudFront certificate.
# Route53 will publish the ACM validation CNAME so the certificate can move to ISSUED.
resource "aws_route53_record" "cloudfront_cert_validation" {
  # The ACM certificate resource provides the necessary DNS record details in the domain_validation_options attribute.
  for_each = {
    for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  # allow_overwrite is needed to ensure that if the certificate is recreated (e.g. due to changes in the domain name), the DNS validation record will be updated accordingly without causing conflicts.
  allow_overwrite = true

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

# Wait for ACM validation to complete.
# CloudFront should not try to use the certificate before ACM marks it as issued.
resource "aws_acm_certificate_validation" "cloudfront_cert_validation" {
  provider                = aws.east
  certificate_arn         = aws_acm_certificate.cloudfront_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]
}