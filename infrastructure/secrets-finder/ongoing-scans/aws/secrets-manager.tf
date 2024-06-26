data "aws_secretsmanager_secret" "api_gateway_web_acl_secret" {
  name = var.api_gateway_web_acl_secret_reference
}

data "aws_secretsmanager_secret_version" "api_gateway_web_acl_secret" {
  secret_id = data.aws_secretsmanager_secret.api_gateway_web_acl_secret.id
}

data "aws_secretsmanager_secret" "datadog_api_token" {
  count = var.datadog_api_key_reference != null ? 1 : 0
  name  = var.datadog_api_key_reference
}

data "aws_secretsmanager_secret" "github_token" {
  name = var.github_token_reference
}

data "aws_secretsmanager_secret" "github_app_secret" {
  name = var.github_app_secret_reference
}
