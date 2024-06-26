variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region where to deploy resources"

  validation {
    condition     = can(regex("^(af|ap|ca|eu|me|sa|us)-(central|north|(north(?:east|west))|south|south(?:east|west)|east|west)-\\d+$", var.aws_region))
    error_message = "You should enter a valid AWS region (https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html)"
  }
}

variable "aws_profile" {
  type        = string
  default     = "default"
  description = "AWS profile to use for authentication"
}

variable "environment_type" {
  type        = string
  default     = "PRODUCTION"
  description = "Environment type"

  validation {
    condition     = contains(["PRODUCTION", "PRE-PRODUCTION", "QUALITY ASSURANCE", "INTEGRATION TESTING", "DEVELOPMENT", "LAB"], var.environment_type)
    error_message = "The environment type should be one of the following values: PRODUCTION, PRE-PRODUCTION, QUALITY ASSURANCE, INTEGRATION TESTING, DEVELOPMENT, LAB (case sensitive)"
  }
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to the resources"
  default     = {}

  validation {
    condition     = alltrue([for v in values(var.tags) : v != ""])
    error_message = "Tag values must not be empty."
  }
}

variable "permissions_boundary_arn" {
  type        = string
  default     = null
  description = "The name of the IAM permissions boundary to attach to the IAM role created by the module"

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:policy\\/([a-zA-Z0-9-_.]+)$", var.permissions_boundary_arn))
    error_message = "The provided ARN is not a valid ARN for a policy"
  }
}

variable "iam_role_path" {
  type        = string
  default     = "/"
  description = "The path to use when creating IAM roles"

  validation {
    condition     = can(regex("^\\/([a-zA-Z0-9]+([-a-zA-Z0-9]*[a-zA-Z0-9]+)?\\/)*$", var.iam_role_path))
    error_message = "The provided path is invalid"
  }
}

variable "project_name" {
  type        = string
  default     = "secrets-finder"
  description = "Name of the project (should be the same across all modules of secrets-finder to ensure consistency)"
}

variable "github_secret_prevention_workflow_org" {
  type        = string
  description = "Name of the GitHub organization where the secret prevention workflows will be triggered"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-_]+[a-zA-Z0-9])*$", var.github_secret_prevention_workflow_org)) && length(var.github_secret_prevention_workflow_org) <= 39
    error_message = "The provided organization name is invalid"
  }
}

variable "github_secret_prevention_workflow_repository" {
  type        = string
  description = "Name of the GitHub repository where the secret prevention workflow will be triggered"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_.]{1,100}$", var.github_secret_prevention_workflow_repository))
    error_message = "The provided repository name is invalid"
  }
}

variable "lambda_archive_file_path" {
  type        = string
  description = "Path to the archive file containing the Lambda function code"

  validation {
    condition     = fileexists(var.lambda_archive_file_path)
    error_message = "The path to the archive file is invalid"
  }
}

variable "hosted_zone" {
  type        = string
  description = "The hosted zone to use for the CloudFront distribution"

  validation {
    condition     = var.hosted_zone != null
    error_message = "The provided hosted zone is invalid"
  }
}

variable "endpoint" {
  type        = string
  description = "Endpoint to use for the CloudFront distribution and Route53 record (if created) (note: 'hosted_zone' variable will be appended to the endpoint to create the full domain name)"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-_]+[a-zA-Z0-9])*$", var.endpoint))
    error_message = "The provided endpoint is invalid"
  }
}

variable "use_custom_certificate" {
  type        = bool
  description = "Whether to use a custom certificate for the CloudFront distribution"
  default     = true
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate to use for the CloudFront distribution when 'use_custom_certificate' variable is true"

  validation {
    condition     = can(regex("^arn:aws:acm:((af|ap|ca|eu|me|sa|us)-(central|north|(north(?:east|west))|south|south(?:east|west)|east|west)-\\d+):[0-9]{12}:certificate\\/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", var.certificate_arn))
    error_message = "The provided ARN is not a valid ARN for a certificate"
  }
}

variable "create_route53_record" {
  type        = bool
  description = "Wether to create a Route53 record for the CloudFront distribution"
  default     = true
}

variable "route53_record_name" {
  type        = string
  default     = null
  description = "Name of the Route53 record to create when 'create_route53_record' is true"

  validation {
    condition     = var.route53_record_name == null || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-_]+[a-zA-Z0-9])*$", var.route53_record_name))
    error_message = "The provided record name is invalid"
  }
}

variable "create_waf_log_group" {
  type        = bool
  description = "Whether to create a log group for the WAF logs"
  default     = true
}

variable "waf_log_group_name" {
  type        = string
  default     = null
  description = "Name of the log group to use for the WAF logs (if 'create_waf_log_group' is true, name is used to create the log group)"

  validation {
    condition     = var.waf_log_group_name == null || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-_]+[a-zA-Z0-9])*$", var.waf_log_group_name))
    error_message = "The provided log group name is invalid"
  }
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "KMS key ARN used to encrypt the log groups. Leave empty if logs should not be encrypted."

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws:kms:(af|ap|ca|eu|me|sa|us)-(central|north|(north(?:east|west))|south|south(?:east|west)|east|west)-\\d+:\\d{12}:key/[a-f0-9-]{36}$", var.kms_key_arn))
    error_message = "The KMS key ARN is invalid"

  }
}

variable "github_token_reference" {
  type        = string
  description = "Name of the secret stored in Secrets Manager and containing the GitHub token to use for triggering the GitHub workflow"

  validation {
    condition     = can(regex("^[a-zA-Z0-9/_+=.@-]{1,512}$", var.github_token_reference))
    error_message = "The secret name is invalid"
  }
}

variable "github_app_secret_reference" {
  type        = string
  description = "Name of the secret stored in Secrets Manager and containing the secret configured for the GitHub App and used for validating signature of incoming requests"

  validation {
    condition     = can(regex("^[a-zA-Z0-9/_+=.@-]{1,512}$", var.github_app_secret_reference))
    error_message = "The secret name is invalid"
  }
}

variable "api_gateway_web_acl_secret_reference" {
  type        = string
  description = "Name of the secret stored in Secrets Manager and containing the secret to use for the configuration of the web ACL of the API Gateway"

  validation {
    condition     = can(regex("^[a-zA-Z0-9/_+=.@-]{1,512}$", var.api_gateway_web_acl_secret_reference))
    error_message = "The secret name is invalid"
  }
}

variable "datadog_api_key_reference" {
  type        = string
  default     = null
  description = "Name of the secret stored in Secrets Manager and containing the Datadog API token. Leave empty if Datadog should not be used."

  validation {
    condition     = var.datadog_api_key_reference == null || can(regex("^[a-zA-Z0-9/_+=.@-]{1,512}$", var.datadog_api_key_reference))
    error_message = "The secret name is invalid"
  }
}

variable "datadog_service_name" {
  type        = string
  default     = null
  description = "Name of the service to use for Datadog monitoring. Leave empty if Datadog should not be used."

  validation {
    condition     = var.datadog_service_name == null || can(regex("^[a-zA-Z0-9-_.]+$", var.datadog_service_name))
    error_message = "The provided service name is invalid"
  }
}
