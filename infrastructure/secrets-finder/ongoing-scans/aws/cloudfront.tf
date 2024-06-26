resource "aws_cloudfront_distribution" "distribution" {
  enabled = true
  comment = "CloudFront distribution serving the API Gateway of Secrets Finder"

  origin {
    origin_id   = var.endpoint
    domain_name = "${aws_api_gateway_deployment.production.rest_api_id}.execute-api.${var.aws_region}.amazonaws.com"
    origin_path = "/production"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "x-waf-secret"
      value = data.aws_secretsmanager_secret_version.api_gateway_web_acl_secret.secret_string
    }
  }

  aliases = ["${var.endpoint}.${var.hosted_zone}"]

  is_ipv6_enabled = true
  http_version    = "http2"

  default_cache_behavior {
    target_origin_id       = var.endpoint
    viewer_protocol_policy = "https-only"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    smooth_streaming       = false
    compress               = true
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    # deprecated
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
      headers = ["Authorization"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.use_custom_certificate ? false : true
    acm_certificate_arn            = var.use_custom_certificate ? var.certificate_arn : null
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  web_acl_id = aws_wafv2_web_acl.cloudfront_web_acl.arn
}
