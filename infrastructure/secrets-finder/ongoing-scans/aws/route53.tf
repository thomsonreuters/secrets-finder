data "aws_route53_zone" "hosted_zone" {
  name         = var.hosted_zone
  private_zone = false
}

resource "aws_route53_record" "record" {
  count   = var.create_route53_record ? 1 : 0
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = var.endpoint
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.distribution.domain_name]
}
