resource "aws_lambda_function" "github_app_event_handler" {
  function_name = var.project_name
  role          = aws_iam_role.lambda_execution_role.arn
  architectures = ["arm64"]
  runtime       = "python3.11"
  handler       = "secrets_finder.handler"

  filename         = var.lambda_archive_file_path
  source_code_hash = filebase64sha256(var.lambda_archive_file_path)

  layers = var.datadog_api_key_reference != null ? [
    "arn:aws:lambda:us-east-1:464622532012:layer:Datadog-Python311-ARM:78",
    "arn:aws:lambda:us-east-1:464622532012:layer:Datadog-Extension-ARM:47"
  ] : null

  environment {
    variables = {
      SECRETS_FINDER_GITHUB_TOKEN_REFERENCE      = var.github_token_reference
      SECRETS_FINDER_GITHUB_APP_SECRET_REFERENCE = var.github_app_secret_reference
      GITHUB_ORGANIZATION                        = var.github_secret_prevention_workflow_org
      GITHUB_REPOSITORY                          = var.github_secret_prevention_workflow_repository

      DD_SITE               = var.datadog_api_key_reference != null ? "datadoghq.com" : null
      DD_API_KEY_SECRET_ARN = var.datadog_api_key_reference != null ? data.aws_secretsmanager_secret.datadog_api_token[0].arn : null
      DD_ENHANCED_METRICS   = var.datadog_api_key_reference != null ? true : null
      DD_TRACE_ENABLED      = var.datadog_api_key_reference != null ? true : null
      DD_LOGS_INJECTION     = var.datadog_api_key_reference != null ? true : null
      DD_ENV                = "prod"
      DD_SERVICE            = var.datadog_api_key_reference != null ? var.datadog_service_name : null
    }
  }

  lifecycle {
    precondition {
      condition     = (var.datadog_api_key_reference == null && var.datadog_service_name == null) || (var.datadog_api_key_reference != null && var.datadog_service_name != null)
      error_message = "Either both or none of the Datadog parameters must be set"
    }
  }
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowInvocationOfLambdaByAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.github_app_event_handler.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.gateway.execution_arn}/*"
}
