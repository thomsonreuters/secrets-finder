data "aws_iam_policy_document" "s3_access_assume_role" {
  count = var.create_access_role ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      identifiers = var.principals_authorized_to_access_bucket
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "s3_access_policy_document" {
  count = var.create_access_role ? 1 : 0
  statement {
    sid       = "ListS3Bucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.secrets_finder.arn]
  }

  statement {
    sid    = "GetAndListObjectsInS3Bucket"
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:ListObject*"
    ]
    resources = ["${aws_s3_bucket.secrets_finder.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  count       = var.create_access_role ? 1 : 0
  name        = "${var.project_name}-s3-access"
  description = "Policy allowing to access the S3 bucket of secrets-finder"
  policy      = data.aws_iam_policy_document.s3_access_policy_document[0].json
}

resource "aws_iam_role_policy_attachment" "allow_access_to_s3_bucket" {
  count = var.create_access_role ? 1 : 0

  policy_arn = aws_iam_policy.s3_access_policy[0].arn
  role       = aws_iam_role.s3_access[0].name
}

resource "aws_iam_role" "s3_access" {
  count                = var.create_access_role ? 1 : 0
  name                 = "${var.project_name}-s3-access"
  assume_role_policy   = data.aws_iam_policy_document.s3_access_assume_role[0].json
  path                 = var.iam_role_path
  permissions_boundary = var.permissions_boundary_arn
}


data "aws_iam_policy_document" "s3_push_assume_role" {
  count = var.create_push_role ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      identifiers = var.principals_authorized_to_push_to_bucket
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}


data "aws_iam_policy_document" "s3_push_policy_document" {
  count = var.create_push_role ? 1 : 0

  statement {
    sid    = "GetAndListObjectsInS3Bucket"
    effect = "Allow"
    actions = [
      "s3:PutObject*"
    ]
    resources = ["${aws_s3_bucket.secrets_finder.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_push_policy" {
  count       = var.create_push_role ? 1 : 0
  name        = "${var.project_name}-s3-push"
  description = "Policy allowing to push objects in the S3 bucket of secrets-finder"
  policy      = data.aws_iam_policy_document.s3_push_policy_document[0].json
}

resource "aws_iam_role_policy_attachment" "allow_push_to_s3_bucket" {
  count = var.create_push_role ? 1 : 0

  policy_arn = aws_iam_policy.s3_push_policy[0].arn
  role       = aws_iam_role.s3_push[0].name
}

resource "aws_iam_role" "s3_push" {
  count                = var.create_push_role ? 1 : 0
  name                 = "${var.project_name}-s3-push"
  assume_role_policy   = data.aws_iam_policy_document.s3_push_assume_role[0].json
  path                 = var.iam_role_path
  permissions_boundary = var.permissions_boundary_arn
}
