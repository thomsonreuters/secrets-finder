terraform {
  required_version = ">=1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.23"
    }
  }

  backend "s3" {
    encrypt = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  default_tags { tags = local.tags }
}

provider "datadog" {
  api_key  = var.enable_datadog_monitors ? data.aws_secretsmanager_secret_version.datadog_api_key[0].secret_string : null
  app_key  = var.enable_datadog_monitors ? data.aws_secretsmanager_secret_version.datadog_application_key[0].secret_string : null
  validate = var.enable_datadog_monitors ? true : false
}
