resource "aws_api_gateway_rest_api" "gateway" {
  name        = var.project_name
  description = "This API Gateway receives events relating to the GitHub organization and forwards them to a Lambda function for secrets detection scanning."
}

resource "aws_api_gateway_resource" "secrets_finder" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  parent_id   = aws_api_gateway_rest_api.gateway.root_resource_id
  path_part   = "secrets-finder"
}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.gateway.id
  resource_id   = aws_api_gateway_resource.secrets_finder.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "log_setting" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id
  stage_name  = aws_api_gateway_stage.production.stage_name
  method_path = "*/*"
  settings {
    logging_level      = "INFO"
    data_trace_enabled = true
    metrics_enabled    = true
  }
}

resource "aws_api_gateway_integration" "github_app_event_handler" {
  rest_api_id             = aws_api_gateway_rest_api.gateway.id
  resource_id             = aws_api_gateway_resource.secrets_finder.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.github_app_event_handler.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_deployment" "production" {
  rest_api_id = aws_api_gateway_rest_api.gateway.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.secrets_finder.id,
      aws_api_gateway_method.post.id,
      aws_api_gateway_integration.github_app_event_handler.id,
      aws_wafv2_web_acl.api_gateway_web_acl.id,
      aws_lambda_function.github_app_event_handler.id,
      aws_iam_role.lambda_execution_role.id
    ]))
  }

  depends_on = [aws_api_gateway_integration.github_app_event_handler]
}

resource "aws_api_gateway_stage" "production" {
  deployment_id        = aws_api_gateway_deployment.production.id
  rest_api_id          = aws_api_gateway_rest_api.gateway.id
  stage_name           = "production"
  xray_tracing_enabled = true
}
