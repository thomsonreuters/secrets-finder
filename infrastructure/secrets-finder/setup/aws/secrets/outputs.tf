output "secrets_finder_secrets" {
  value       = { for s in aws_secretsmanager_secret.secrets_finder_secrets : s.name => s.arn }
  description = "ARNs of the secrets stored for use within secrets-finder"
}
