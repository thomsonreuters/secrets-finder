output "api_gateway_url" {
  value = aws_api_gateway_deployment.production.invoke_url
}

output "cloudwatch_logs" {
  value = aws_cloudwatch_log_group.logs.arn
}

output "lambda_execution_role" {
  value = aws_iam_role.lambda_execution_role.arn
}

output "lambda_function" {
  value = aws_lambda_function.github_app_event_handler.arn
}

output "cloudfront_distribution" {
  value = aws_cloudfront_distribution.distribution.domain_name
}

output "route53_record" {
  value = var.create_route53_record != null ? aws_route53_record.record[*].fqdn : null
}
