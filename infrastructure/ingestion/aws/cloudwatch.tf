resource "aws_cloudwatch_event_rule" "ingestion_sfn_trigger_rule" {
  name                = "${var.project_name}-ingestion-sfn-trigger"
  description         = "Triggers the Step function on schedule"
  schedule_expression = var.ingestion_schedule
  state               = var.disable_ingestion_schedule ? "DISABLED" : "ENABLED"
}

resource "aws_cloudwatch_event_target" "ingestion_sfn_trigger" {
  rule     = aws_cloudwatch_event_rule.ingestion_sfn_trigger_rule.name
  arn      = aws_sfn_state_machine.ingestion-step-function.arn
  role_arn = aws_iam_role.cloudwatch_role.arn

  depends_on = [
    aws_iam_role.cloudwatch_role,
    aws_iam_role_policy.cloudwatch_policy,
  ]
}
