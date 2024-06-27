resource "null_resource" "ingestion_lambda_build" {
  provisioner "local-exec" {
    command     = "./package.sh"
    working_dir = "${local.ingestion_lambda_dir}/"
  }

  triggers = {
    always_run = timestamp()
  }
}

data "local_file" "ingestion_lambda_build" {
  filename   = local.ingestion_lambda_archive
  depends_on = [null_resource.ingestion_lambda_build]
}

resource "aws_lambda_function" "ingestion-lambda" {
  function_name    = "${var.project_name}-ingestion-lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  architectures    = ["arm64"]
  runtime          = "python3.9"
  handler          = "ingestion.handler"
  timeout          = 900 # 15 minutes
  memory_size      = 512 # 512 MB
  filename         = local.ingestion_lambda_archive
  source_code_hash = data.local_file.ingestion_lambda_build.content_sha256

  vpc_config {
    subnet_ids         = [data.aws_subnet.selected.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  ephemeral_storage {
    size = 1024 # 1 GB
  }

  environment {
    variables = {
      BUCKET_NAME = var.s3_bucket_name
      DB_URL      = local.db_url
    }
  }

  depends_on = [
    data.local_file.ingestion_lambda_build,
    aws_iam_role.lambda_execution_role,
    aws_iam_policy.policy_for_execution_role,
    aws_iam_role_policy_attachment.LambdaExecutionRolePolicyAttachment
  ]
}

resource "null_resource" "migration_lambda_build" {
  provisioner "local-exec" {
    command     = "./package.sh"
    working_dir = "${local.migration_lambda_dir}/"
  }

  triggers = {
    always_run = timestamp()
  }
}

data "local_file" "migration_lambda_build" {
  filename   = local.migration_lambda_archive
  depends_on = [null_resource.migration_lambda_build]
}

resource "aws_lambda_function" "migration-lambda" {
  function_name    = "${var.project_name}-migration-lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  architectures    = ["arm64"]
  runtime          = "python3.9"
  handler          = "migrate.migrate"
  timeout          = 60  # 1 minute
  memory_size      = 512 # 512 MB
  filename         = local.migration_lambda_archive
  source_code_hash = data.local_file.migration_lambda_build.content_sha256

  vpc_config {
    subnet_ids         = [data.aws_subnet.selected.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  ephemeral_storage {
    size = 512 # 512 MB
  }

  environment {
    variables = {
      DB_URL = local.db_url
    }
  }

  depends_on = [
    data.local_file.migration_lambda_build,
    aws_iam_role.lambda_execution_role,
    aws_iam_policy.policy_for_execution_role,
    aws_iam_role_policy_attachment.LambdaExecutionRolePolicyAttachment
  ]
}
