# API Gateway
resource "aws_wafv2_web_acl" "api_gateway_web_acl" {
  name        = "${var.project_name}-api-gateway-webacl"
  description = "Web ACL for the API Gateway deployed by secrets-finder"
  scope       = "REGIONAL"

  custom_response_body {
    key          = "unauthorized"
    content      = "Unauthorized request"
    content_type = "TEXT_PLAIN"
  }

  default_action {
    block {
      custom_response {
        response_code            = 403
        custom_response_body_key = "unauthorized"
      }
    }
  }

  rule {
    name     = "aws-managed-rules-common-rule-set"
    priority = 0

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.project_name}-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "aws-managed-rules-bot-control-rule-set"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.project_name}-AWSManagedRulesBotControlRuleSet"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "aws-managed-rules-known-bad-inputs-rule-set"
    priority = 2

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.project_name}-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "aws-managed-rules-amazon-ip-reputation-list"
    priority = 3

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.project_name}-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "authorize-requests"
    priority = 4

    action {
      allow {}
    }

    statement {
      byte_match_statement {
        positional_constraint = "EXACTLY"
        search_string         = data.aws_secretsmanager_secret_version.api_gateway_web_acl_secret.secret_string
        field_to_match {
          single_header {
            name = "x-waf-secret"
          }
        }
        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-api-gateway-rule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-api-gateway-web-acl"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "api_gateway_web_acl_logging" {
  count                   = var.waf_log_group_name != null ? 1 : 0
  log_destination_configs = var.create_waf_log_group != null ? ["${aws_cloudwatch_log_group.waf_log_group[0].arn}:*"] : ["${data.aws_cloudwatch_log_group.existing_waf_log_group[0].arn}:*"]
  resource_arn            = aws_wafv2_web_acl.api_gateway_web_acl.arn
}

resource "aws_wafv2_web_acl_association" "api_gateway_web_acl_association" {
  resource_arn = aws_api_gateway_stage.production.arn
  web_acl_arn  = aws_wafv2_web_acl.api_gateway_web_acl.arn
}



# CloudFront
resource "aws_wafv2_web_acl" "cloudfront_web_acl" {
  name        = "${var.project_name}-cloudfront"
  description = "Web ACL for the CloudFront distribution deployed by secrets-finder"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "aws-managed-rules-amazon-ip-reputation-list"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-managed-rules-common-rule-set"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            allow {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-managed-rules-known-bad-inputs-rule-set"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-managed-rules-bot-control-rule-set"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"

        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "TARGETED"
          }
        }

        rule_action_override {
          name = "CategoryHttpLibrary"
          action_to_use {
            block {}
          }
        }

        rule_action_override {
          name = "SignalNonBrowserUserAgent"
          action_to_use {
            allow {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-AWSManagedRulesBotControlRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-web-acl"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "cloudfront_web_acl_logging" {
  count                   = var.waf_log_group_name != null ? 1 : 0
  log_destination_configs = [var.create_waf_log_group != null ? aws_cloudwatch_log_group.waf_log_group[0].arn : data.aws_cloudwatch_log_group.existing_waf_log_group[0].arn]
  resource_arn            = aws_wafv2_web_acl.cloudfront_web_acl.arn
}
