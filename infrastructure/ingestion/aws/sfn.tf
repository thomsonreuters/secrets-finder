resource "aws_sfn_state_machine" "ingestion-step-function" {
  name     = "${var.project_name}-ingestion-step-function"
  role_arn = aws_iam_role.sfn_role.arn
  definition = templatefile("${local.configuration_dir}/ingestion_sfn_definition.json", {
    migrate_lambda_arn   = "${aws_lambda_function.migration-lambda.arn}",
    ingestion_lambda_arn = "${aws_lambda_function.ingestion-lambda.arn}"
  })

  depends_on = [
    aws_iam_role.sfn_role,
    aws_iam_role_policy.sfn_policy,
  ]
}
