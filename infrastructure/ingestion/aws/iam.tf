# Lambda execution role
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
  name                 = "${var.project_name}-ingestion-lambda-execution-role"
  assume_role_policy   = data.aws_iam_policy_document.lambda_assume_role.json
  path                 = "/"
  permissions_boundary = var.permissions_boundary_arn
}

data "aws_iam_policy_document" "permissions_for_execution_role" {
  statement {
    sid    = "WriteToCloudWatchLogGroup"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid    = "AllowAccessToBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${local.s3_bucket_arn}",
      "${local.s3_bucket_arn}/*"
    ]
  }

  statement {
    sid    = "AllowAccessToRDS"
    effect = "Allow"
    actions = [
      "rds-data:ExecuteStatement",
      "rds-data:BatchExecuteStatement",
      "rds-data:BeginTransaction",
      "rds-data:CommitTransaction",
      "rds-data:RollbackTransaction"
    ]
    resources = [
      aws_db_instance.rds_postgres.arn
    ]
  }

  statement {
    sid    = "AllowEC2Perms"
    effect = "Allow"
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "policy_for_execution_role" {
  name        = "${var.project_name}-ingestion-lambda-execution-role-permissions"
  description = "Policy granting necessary permissions to Lambda execution instance"
  policy      = data.aws_iam_policy_document.permissions_for_execution_role.json
}

resource "aws_iam_role_policy_attachment" "LambdaExecutionRolePolicyAttachment" {
  policy_arn = aws_iam_policy.policy_for_execution_role.arn
  role       = aws_iam_role.lambda_execution_role.name
}

# Step function role

data "aws_iam_policy_document" "sf_assume_role" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["states.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "sfn_role" {
  name                 = "${var.project_name}-ingestion-sf-execution-role"
  path                 = "/"
  permissions_boundary = var.permissions_boundary_arn
  assume_role_policy   = data.aws_iam_policy_document.sf_assume_role.json
}

data "aws_iam_policy_document" "sfn_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      aws_lambda_function.ingestion-lambda.arn,
      aws_lambda_function.migration-lambda.arn
    ]
  }
}

resource "aws_iam_role_policy" "sfn_policy" {
  name   = "${var.project_name}-ingestion-sf-execution-policy"
  role   = aws_iam_role.sfn_role.id
  policy = data.aws_iam_policy_document.sfn_policy_document.json
}

# Cloudwatch role

data "aws_iam_policy_document" "cloudwatch_assume_role" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["events.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudwatch_role" {
  name                 = "${var.project_name}-ingestion-cloud-watch-role"
  path                 = "/"
  permissions_boundary = var.permissions_boundary_arn
  assume_role_policy   = data.aws_iam_policy_document.cloudwatch_assume_role.json
}

data "aws_iam_policy_document" "cloudwatch_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "states:StartExecution"
    ]
    resources = [
      aws_sfn_state_machine.ingestion-step-function.arn
    ]
  }
}

resource "aws_iam_role_policy" "cloudwatch_policy" {
  name   = "${var.project_name}-cloudwatch-event-policy"
  role   = aws_iam_role.cloudwatch_role.id
  policy = data.aws_iam_policy_document.cloudwatch_policy_document.json
}
