resource "aws_cloudwatch_log_group" "logs" {
  name              = "/aws/lambda/${aws_lambda_function.github_app_event_handler.function_name}"
  retention_in_days = 30

  kms_key_id = var.kms_key_arn
}

resource "aws_cloudwatch_log_group" "waf_log_group" {
  count             = var.create_waf_log_group ? 1 : 0
  name              = var.waf_log_group_name
  retention_in_days = 30

  kms_key_id = var.kms_key_arn

  lifecycle {
    precondition {
      condition     = (var.create_waf_log_group == true) && (var.waf_log_group_name != null)
      error_message = "The WAF log group name to create is missing"
    }
  }
}

data "aws_cloudwatch_log_group" "existing_waf_log_group" {
  count = var.create_waf_log_group || var.waf_log_group_name == null ? 0 : 1
  name  = var.waf_log_group_name
}
