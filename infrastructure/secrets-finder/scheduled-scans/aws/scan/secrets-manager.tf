data "aws_secretsmanager_secret" "datadog_api_key" {
  count = var.datadog_api_key_reference != null ? 1 : 0
  name  = var.datadog_api_key_reference
}

data "aws_secretsmanager_secret" "credentials" {
  name = var.credentials_reference
}
