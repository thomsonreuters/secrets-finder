resource "aws_iam_role" "cloudwatch_role" {
  name                 = "${var.project_name}-cloudwatch"
  assume_role_policy   = data.aws_iam_policy_document.cloudwatch_assume_role.json
  path                 = var.iam_role_path
  permissions_boundary = var.permissions_boundary_arn
}

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

data "aws_iam_policy_document" "policy_document_start_codebuild" {
  statement {
    effect    = "Allow"
    actions   = ["codebuild:StartBuild"]
    resources = [aws_codebuild_project.secrets_finder.arn]
  }
}

resource "aws_iam_policy" "start_codebuild" {
  name        = "${var.project_name}-start-codebuild"
  description = "Allows to start new secrets detection scan through CodeBuild"
  policy      = data.aws_iam_policy_document.policy_document_start_codebuild.json
}

resource "aws_iam_role_policy_attachment" "start_codebuild" {
  policy_arn = aws_iam_policy.start_codebuild.arn
  role       = aws_iam_role.cloudwatch_role.name
}

data "aws_iam_policy_document" "policy_document_tag_cloudwatch_event" {
  statement {
    effect    = "Allow"
    actions   = ["events:TagResource"]
    resources = [aws_cloudwatch_event_rule.start_codebuild.arn]
  }
}

resource "aws_iam_policy" "tag_cloudwatch_event" {
  name        = "${var.project_name}-tag-cloudwatch-event"
  description = "Policy allowing to tag the event responsible for launching a new secrets detection scan through CodeBuild"
  policy      = data.aws_iam_policy_document.policy_document_tag_cloudwatch_event.json
}

resource "aws_iam_role_policy_attachment" "tag_event" {
  policy_arn = aws_iam_policy.tag_cloudwatch_event.arn
  role       = aws_iam_role.cloudwatch_role.name
}

resource "aws_iam_role" "codebuild_role" {
  name                 = "${var.project_name}-codebuild"
  assume_role_policy   = data.aws_iam_policy_document.codebuild_assume_policy.json
  path                 = var.iam_role_path
  permissions_boundary = var.permissions_boundary_arn
}

data "aws_iam_policy_document" "codebuild_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "codebuild.amazonaws.com",
        "events.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "policy_document_permissions_for_codebuild" {
  statement {
    sid    = "StartCodeBuildToPerformTruffleHogScan"
    effect = "Allow"
    actions = [
      "codebuild:StartBuild"
    ]
    resources = [aws_codebuild_project.secrets_finder.arn]
  }

  statement {
    sid    = "AllowManagementOfLogsRelatingToCodeBuild"
    effect = "Allow"
    actions = [
      "logs:*"
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.project_name}*"]
  }

  dynamic "statement" {
    for_each = var.sns_topic_receiver != null ? [var.sns_topic_receiver] : []
    content {
      sid    = "AllowToEmitImportantNotifications"
      effect = "Allow"
      actions = [
        "sns:Publish"
      ]
      resources = [aws_sns_topic.important_notifications[0].arn]
    }
  }

  dynamic "statement" {
    for_each = var.token_reference_github_organization_hosting_secrets_finder != null ? [var.token_reference_github_organization_hosting_secrets_finder] : []
    content {
      sid    = "FetchGitHubToken"
      effect = "Allow"
      actions = [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue"
      ]
      resources = [data.aws_secretsmanager_secret.token_reference_github_organization_hosting_secrets_finder[0].arn]
    }
  }

  dynamic "statement" {
    for_each = (var.enable_datadog_monitors == true) ? [var.datadog_api_key_reference] : []
    content {
      sid    = "FetchDatadogAPIKey"
      effect = "Allow"
      actions = [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue"
      ]
      resources = [
        "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${statement.value}-*"
      ]
    }
  }

  dynamic "statement" {
    for_each = (var.enable_datadog_monitors == true) ? [var.datadog_application_key_reference] : []
    content {
      sid    = "FetchDatadogApplicationKey"
      effect = "Allow"
      actions = [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue"
      ]
      resources = [
        "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${statement.value}-*"
      ]
    }
  }

  statement {
    sid    = "ReviewStateOfAllCredentialsReferences"
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      for reference in keys(data.aws_secretsmanager_secret.credentials_references) : data.aws_secretsmanager_secret.credentials_references[reference].arn
    ]
  }

  statement {
    sid    = "AuthorizeActionsOnIAMResourcesDeployedWhenScanning"
    effect = "Allow"
    actions = [
      "iam:*"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-ec2-role",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-ec2-permissions",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project_name}-instance-profile"
    ]
  }

  dynamic "statement" {
    for_each = (var.permissions_boundary_arn == true) ? ["add"] : []
    content {
      sid    = "AllowUseOfPermissionsBoundary"
      effect = "Allow"
      actions = [
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:AttachRolePolicy"
      ]
      resources = [
        var.permissions_boundary_arn
      ]
    }
  }

  statement {
    sid    = "AuthorizeManagementOfS3BucketUsedBySecretsFinder"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  statement {
    sid       = "ListS3BucketUsedForRemoteStateManagement"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.s3_bucket_remote_states}"]
  }

  statement {
    sid    = "GetAndPutObjectsInS3BucketUsedForRemoteStateManagement"
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:PutObject*"
    ]
    resources = ["arn:aws:s3:::${var.s3_bucket_remote_states}/*"]
  }

  statement {
    sid    = "ManageItemsInDynamoDBTableUsedForRemoteStateManagement"
    effect = "Allow"
    actions = [
      "dynamodb:*Item"
    ]
    resources = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_remote_states}"]
  }

  statement {
    sid    = "ListKeysAndAliases"
    effect = "Allow"
    actions = [
      "kms:ListKeys",
      "kms:ListAliases"
    ]

    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.ebs_encryption_key_arn != null ? [var.ebs_encryption_key_arn] : []
    content {
      sid    = "AllowEBSVolumeEncryption"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:ListKeyPolicies",
        "kms:ListRetirableGrants",
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:ListResourceTags",
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*"
      ]
      resources = [data.aws_kms_key.ebs_encryption_key[0].arn]
    }
  }

  dynamic "statement" {
    for_each = var.ami_encryption_key_arn != null ? [var.ami_encryption_key_arn] : []
    content {
      sid    = "AllowUseOfAMIEncryptionKey"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:GenerateDataKey*"
      ]
      resources = [data.aws_kms_key.ami_encryption_key[0].arn]
    }
  }

  statement {
    sid    = "GetInformationAboutEC2Resources"
    effect = "Allow"
    actions = [
      "ec2:DescribeVpc*",
      "ec2:DescribeSubnets",
      "ec2:DescribeImages",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeVolumes",
      "ec2:DescribeInstances",
      "ec2:RunInstances",
      "ec2:DescribeTags",
      "ec2:DescribeInstanceCreditSpecifications",
      "ec2:CreateTags",
      "ec2:ModifyInstanceAttribute"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:*"
    ]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"]

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/Name"
      values   = ["${var.project_name}*"]
    }
  }
}

resource "aws_iam_policy" "permissions_for_codebuild" {
  name   = "${var.project_name}-codebuild-permissions"
  policy = data.aws_iam_policy_document.policy_document_permissions_for_codebuild.json
}

resource "aws_iam_role_policy_attachment" "permissions_for_codebuild" {
  policy_arn = aws_iam_policy.permissions_for_codebuild.arn
  role       = aws_iam_role.codebuild_role.name
}
