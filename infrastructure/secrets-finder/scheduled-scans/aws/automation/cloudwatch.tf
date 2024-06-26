resource "aws_cloudwatch_event_rule" "start_codebuild" {
  name                = var.project_name
  description         = "Event rule to start the CodeBuild build project responsible to trigger scheduled scans for secrets detection"
  schedule_expression = var.start_schedule

  depends_on = [
    aws_s3_object.scanner_static_files,
    aws_s3_object.backend_static_files,
    aws_s3_object.scanner_template_files,
    aws_s3_object.backend_template_files,
    aws_s3_object.scanning_files,
    aws_s3_object.trufflehog_configuration_file
  ]
}

resource "aws_cloudwatch_event_target" "trigger_codebuild_start" {
  target_id = "StartCodeBuild"
  rule      = aws_cloudwatch_event_rule.start_codebuild.name
  arn       = aws_codebuild_project.secrets_finder.arn
  role_arn  = aws_iam_role.codebuild_role.arn
}
