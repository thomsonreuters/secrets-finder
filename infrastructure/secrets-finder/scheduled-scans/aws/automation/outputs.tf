output "codebuild_arn" {
  value = aws_codebuild_project.secrets_finder.arn
}

output "event_rule_arn" {
  value = aws_cloudwatch_event_rule.start_codebuild.arn
}
