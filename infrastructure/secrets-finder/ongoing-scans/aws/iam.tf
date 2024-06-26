data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name                 = "${var.project_name}-execution-role"
  assume_role_policy   = data.aws_iam_policy_document.lambda_assume_role.json
  path                 = var.iam_role_path
  permissions_boundary = var.permissions_boundary_arn
}

data "aws_iam_policy_document" "permissions_for_execution_role" {
  dynamic "statement" {
    for_each = (var.datadog_api_key_reference != null) ? [var.datadog_api_key_reference] : []
    content {
      sid    = "FetchDatadogAPIToken"
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resources = [data.aws_secretsmanager_secret.datadog_api_token[0].arn]
    }
  }

  statement {
    sid    = "FetchGitHubToken"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [data.aws_secretsmanager_secret.github_token.arn]
  }

  statement {
    sid    = "FetchGitHubAppSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [data.aws_secretsmanager_secret.github_app_secret.arn]
  }

  statement {
    sid    = "WriteToCloudWatchLogGroup"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "policy_for_execution_role" {
  name        = "${var.project_name}-execution-role-permissions"
  description = "Policy granting necessary permissions to Lambda execution instance"
  policy      = data.aws_iam_policy_document.permissions_for_execution_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  policy_arn = aws_iam_policy.policy_for_execution_role.arn
  role       = aws_iam_role.lambda_execution_role.name
}
