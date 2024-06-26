resource "aws_iam_role" "ec2_role" {
  name                 = "${var.project_name}-ec2-role"
  assume_role_policy   = data.aws_iam_policy_document.ec2_assume_role.json
  path                 = var.iam_role_path
  permissions_boundary = var.permissions_boundary_arn
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "policy_document_permissions_for_ec2_instance" {
  statement {
    sid       = "ListS3Bucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [data.aws_s3_bucket.secrets_finder.arn]
  }

  statement {
    sid    = "GetAndPutObjectsInS3Bucket"
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:PutObject*"
    ]
    resources = ["${data.aws_s3_bucket.secrets_finder.arn}/*"]
  }

  statement {
    sid    = "AccessSecretInSecretsManager"
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [data.aws_secretsmanager_secret.credentials.arn]
  }

  dynamic "statement" {
    for_each = (var.datadog_api_key_reference != null) ? [var.datadog_api_key_reference] : []
    content {
      sid    = "FetchDatadogAPIKey"
      effect = "Allow"
      actions = [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue"
      ]
      resources = [data.aws_secretsmanager_secret.datadog_api_key[0].arn]
    }
  }

  statement {
    sid    = "AllowTerminationOfEC2Instance"
    effect = "Allow"
    actions = [
      "ec2:TerminateInstances"
    ]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"]

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/Name"
      values   = ["${var.project_name}*"]
    }

    condition {
      test     = "StringLike"
      variable = "ec2:InstanceProfile"
      values   = [aws_iam_instance_profile.ec2_instance_profile.arn]
    }
  }

  dynamic "statement" {
    for_each = var.sns_topic_arn != null ? [var.sns_topic_arn] : []
    content {
      sid    = "AllowToEmitImportantNotifications"
      effect = "Allow"
      actions = [
        "sns:Publish"
      ]
      resources = [var.sns_topic_arn]
    }
  }
}

resource "aws_iam_policy" "permissions_for_ec2_instance" {
  name        = "${var.project_name}-ec2-permissions"
  description = "Policy granting necessary permissions to EC2 instance"
  policy      = data.aws_iam_policy_document.policy_document_permissions_for_ec2_instance.json
}

resource "aws_iam_role_policy_attachment" "permissions_for_ec2_instance" {
  policy_arn = aws_iam_policy.permissions_for_ec2_instance.arn
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}
