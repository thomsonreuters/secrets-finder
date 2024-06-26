resource "aws_codebuild_project" "secrets_finder" {
  badge_enabled  = false
  build_timeout  = 60
  name           = var.project_name
  queued_timeout = 480
  service_role   = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "PROJECT_NAME"
      value = var.project_name
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "VPC_NAME"
      value = var.vpc_name
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "SUBNET_NAME"
      value = var.subnet_name
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "S3_BUCKET_NAME"
      value = var.s3_bucket_name
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "INSTANCE_USER"
      value = var.instance_user
      type  = "PLAINTEXT"
    }

    dynamic "environment_variable" {
      for_each = (var.token_reference_github_organization_hosting_secrets_finder != null) ? [var.token_reference_github_organization_hosting_secrets_finder] : []
      content {
        name  = "GITHUB_TOKEN"
        value = data.aws_secretsmanager_secret.token_reference_github_organization_hosting_secrets_finder[0].arn
        type  = "SECRETS_MANAGER"
      }
    }

    environment_variable {
      name  = "GITHUB_ORG_SECRETS_FINDER"
      value = var.github_organization_hosting_secrets_finder
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "GITHUB_REPOSITORY_SECRETS_FINDER"
      value = var.github_repository_hosting_secrets_finder
      type  = "PLAINTEXT"
    }

    dynamic "environment_variable" {
      for_each = var.sns_topic_receiver != null ? [aws_sns_topic.important_notifications[0].arn] : []
      content {
        name  = "SNS_TOPIC_ARN"
        value = environment_variable.value
        type  = "PLAINTEXT"
      }
    }

    environment_variable {
      name  = "TERRAFORM_VERSION"
      value = var.terraform_version
      type  = "PLAINTEXT"
    }

    dynamic "environment_variable" {
      for_each = (var.datadog_api_key_reference != null) ? [var.datadog_api_key_reference] : []
      content {
        name  = "DATADOG_API_KEY_REFERENCE"
        value = environment_variable.value
        type  = "PLAINTEXT"
      }
    }

    dynamic "environment_variable" {
      for_each = (var.enable_datadog_monitors == true) ? [var.datadog_account] : []
      content {
        name  = "DATADOG_ACCOUNT_NAME"
        value = environment_variable.value
        type  = "PLAINTEXT"
      }
    }
  }

  source {
    buildspec           = templatefile(local.buildspec_file, { scans = var.scans })
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "NO_SOURCE"
  }

  lifecycle {
    precondition {
      condition     = (var.enable_datadog_monitors == false) || (var.enable_datadog_monitors == true && var.datadog_account != null)
      error_message = "Datadog monitors were enabled but no Datadog account was provided to collect EC2 instance metrics (variable 'datadog_account' has no value)"
    }
  }

  depends_on = [
    aws_s3_object.scanner_static_files,
    aws_s3_object.backend_static_files,
    aws_s3_object.scanner_template_files,
    aws_s3_object.backend_template_files,
    aws_s3_object.scanning_files
  ]
}
