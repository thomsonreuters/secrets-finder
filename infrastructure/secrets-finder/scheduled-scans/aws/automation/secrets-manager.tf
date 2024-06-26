data "aws_secretsmanager_secret" "token_reference_github_organization_hosting_secrets_finder" {
  count = var.token_reference_github_organization_hosting_secrets_finder != null ? 1 : 0
  name  = var.token_reference_github_organization_hosting_secrets_finder
}

data "aws_secretsmanager_secret" "datadog_api_key" {
  count = var.enable_datadog_monitors == true ? 1 : 0
  name  = var.datadog_api_key_reference

  lifecycle {
    precondition {
      condition     = var.datadog_api_key_reference != null
      error_message = "Datadog monitors should be set up, but no secret reference to Secrets Manager was provided using the 'datadog_api_key_reference' variable."
    }
  }
}

data "aws_secretsmanager_secret_version" "datadog_api_key" {
  count     = var.enable_datadog_monitors ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.datadog_api_key[0].id

  lifecycle {
    precondition {
      condition     = var.datadog_api_key_reference != null
      error_message = "Datadog monitors should be set up, but no secret reference to Secrets Manager was provided using the 'datadog_api_key_reference' variable."
    }
  }
}

data "aws_secretsmanager_secret" "datadog_application_key" {
  count = var.enable_datadog_monitors == true ? 1 : 0
  name  = var.datadog_application_key_reference

  lifecycle {
    precondition {
      condition     = var.datadog_application_key_reference != null
      error_message = "Datadog monitors should be set up, but no secret reference to Secrets Manager was provided using the 'datadog_application_key_reference' variable."
    }
  }
}

data "aws_secretsmanager_secret_version" "datadog_application_key" {
  count     = var.enable_datadog_monitors ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.datadog_application_key[0].id

  lifecycle {
    precondition {
      condition     = var.datadog_application_key_reference != null
      error_message = "Datadog monitors should be set up, but no secret reference to Secrets Manager was provided using the 'datadog_application_key_reference' variable."
    }
  }
}

data "aws_secretsmanager_secret" "credentials_references" {
  for_each = toset(local.all_credentials_references)
  name     = each.value
}
