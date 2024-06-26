data "aws_secretsmanager_secret" "github_token_secret" {
  name = var.github_token_secret_name
}
