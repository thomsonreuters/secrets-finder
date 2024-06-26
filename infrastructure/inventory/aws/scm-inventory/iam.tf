## Role assumable by EC2 instance
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

resource "aws_iam_role" "ec2_role" {
  name                 = "${var.project_name}-ec2-role"
  assume_role_policy   = data.aws_iam_policy_document.ec2_assume_role.json
  path                 = "/"
  permissions_boundary = var.permissions_boundary_arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

data "aws_iam_policy_document" "policy_document_permissions_for_ec2_instance" {
  # S3: Get and put objects in S3 bucket
  statement {
    sid       = "ListS3Bucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [data.aws_s3_bucket.resources_and_results.arn]
  }

  statement {
    sid    = "GetAndPutObjectsInS3Bucket"
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:PutObject*"
    ]
    resources = ["${data.aws_s3_bucket.resources_and_results.arn}/*"]
  }

  # Secrets Manager: Get GitHub API token

  statement {
    sid    = "FetchGitHubToken"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.github_token_secret_name}-*"]
  }

  # EC2: Allow instance to schedule termination for itself (end of scan)
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
}

resource "aws_iam_policy" "permissions_for_ec2_instance" {
  name        = "${var.project_name}-ec2-permissions"
  description = "Policy granting necessary permissions to EC2 instance"
  policy      = data.aws_iam_policy_document.policy_document_permissions_for_ec2_instance.json
}

resource "aws_iam_role_policy_attachment" "PermissionsForEC2InstancePolicyAttachment" {
  policy_arn = aws_iam_policy.permissions_for_ec2_instance.arn
  role       = aws_iam_role.ec2_role.name
}


data "aws_iam_policy_document" "s3_access_policy_document" {
  statement {
    sid       = "ListS3Bucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [data.aws_s3_bucket.resources_and_results.arn]
  }

  statement {
    sid    = "GetAndListObjectsInS3Bucket"
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:ListObject*"
    ]
    resources = ["${data.aws_s3_bucket.resources_and_results.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.project_name}-s3-access"
  description = "Policy allowing to access the S3 bucket used for Trufflehog"
  policy      = data.aws_iam_policy_document.s3_access_policy_document.json
}
