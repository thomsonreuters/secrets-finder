output "s3_bucket" {
  value       = aws_s3_bucket.secrets_finder.arn
  description = "ARN of the S3 bucket used for secrets-finder"
}

output "s3_access_role" {
  value      = var.create_access_role == true ? aws_iam_role.s3_access[*].arn : null
  depends_on = [aws_iam_role.s3_access]
}

output "s3_push_role" {
  value      = var.create_push_role == true ? aws_iam_role.s3_push[*].arn : null
  depends_on = [aws_iam_role.s3_push]
}
