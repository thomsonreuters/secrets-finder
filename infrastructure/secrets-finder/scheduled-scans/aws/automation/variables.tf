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
  description = "Environment (PRODUCTION, PRE-PRODUCTION, QUALITY ASSURANCE, INTEGRATION TESTING, DEVELOPMENT, LAB)"

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
  description = "The name of the IAM permissions boundary to attach to the IAM roles created by the module"

  validation {
    condition     = var.permissions_boundary_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:policy\\/([a-zA-Z0-9-_.]+)$", var.permissions_boundary_arn))
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

variable "vpc_name" {
  type        = string
  description = "Identifier of the VPC to use for secrets-finder"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet where to deploy the resources (wildcards are allowed: first match is used)"
}


variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket containing files used for secrets detection scans"
}

variable "s3_bucket_remote_states" {
  type        = string
  description = "Name of the S3 bucket containing the remote states of the infrastructure"

}

variable "dynamodb_table_remote_states" {
  type        = string
  description = "Name of the DynamoDB table containing the locks used for the remote states representing the infrastructure"
}

variable "start_schedule" {
  type        = string
  default     = "cron(0 6 ? * MON *)"
  description = "The cron specifying when a new scanning instance should be set up (default is: every Monday at 06:00, expected format: https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html#CronExpressions)"
}

variable "token_reference_github_organization_hosting_secrets_finder" {
  type        = string
  default     = null
  description = "Name of the secret stored in Secrets Manager containing the GitHub token for the organization hosting the secrets-finder code. Leave empty if the repository is publicly accessible."

  validation {
    condition     = var.token_reference_github_organization_hosting_secrets_finder == null || can(regex("^[a-zA-Z0-9/_+=.@-]{1,512}$", var.token_reference_github_organization_hosting_secrets_finder))
    error_message = "The secret name is invalid"
  }
}

variable "github_organization_hosting_secrets_finder" {
  type        = string
  description = "Name of the GitHub Organization where the repository containing the secrets-finder code is hosted"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,38}$", var.github_organization_hosting_secrets_finder))
    error_message = "The GitHub organization name must start with a letter or number, can include dashes, and be between 1 and 39 characters."
  }
}

variable "github_repository_hosting_secrets_finder" {
  type        = string
  description = "Name of the GitHub Repository containing the secrets-finder code"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{1,100}$", var.github_repository_hosting_secrets_finder))
    error_message = "The GitHub repository name must be between 1 and 100 characters, and can include letters, numbers, underscores, periods, and dashes."
  }
}

variable "sns_topic_receiver" {
  type        = string
  default     = null
  description = "Email address of the receiver of the SNS topic to which important notifications are sent. Leave empty if no notifications should be sent."

  validation {
    condition     = var.sns_topic_receiver == null || can(regex("^(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])$", var.sns_topic_receiver))
    error_message = "The email address of the receiver is invalid."
  }
}

variable "ebs_encryption_key_arn" {
  type        = string
  default     = null
  description = "The ARN of the KMS key used to encrypt the EBS volumes"
}

variable "ami_encryption_key_arn" {
  type        = string
  default     = null
  description = "The ARN of the KMS key used to decrypt/encrypt the AMI used for the scanning instances"
}

variable "terraform_version" {
  type        = string
  default     = "1.8.5"
  description = "Version of Terraform to use when starting a new scan from CodeBuild"

  validation {
    condition     = can(regex("^([0-9]+)\\.([0-9]+)\\.([0-9]+)(?:-([0-9A-Za-z-]+(?:\\.[0-9A-Za-z-]+)*))?(?:\\+[0-9A-Za-z-]+)?$", var.terraform_version))
    error_message = "The Terraform version should be in the format 'x.y.z'"
  }
}

variable "trufflehog_configuration_file" {
  type        = string
  default     = null
  description = "Path to the Trufflehog configuration file. Leave empty if no configuration file should be used."

  validation {
    condition     = var.trufflehog_configuration_file == null || can(fileexists(var.trufflehog_configuration_file))
    error_message = "The Trufflehog configuration file must exist."
  }

}

variable "instance_user" {
  type        = string
  default     = "secrets-finder"
  description = "Username to create and use on the instances started for the scanning process"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-_]+[a-zA-Z0-9])*$", var.instance_user))
    error_message = "instance_user must contain only alphanumeric characters, dashes, and underscores, and must not start or end with a dash or underscore."
  }
}

variable "scans" {
  description = "List of scans to perform"
  type = list(object({
    identifier                    = string
    scm                           = string
    credentials_reference         = string
    ec2_instance_type             = string
    files                         = optional(list(string))
    repositories_to_scan          = optional(string)
    terminate_instance_on_error   = optional(bool)
    terminate_instance_after_scan = optional(bool)
    report_only_verified          = optional(bool)
  }))

  validation {
    condition     = length(var.scans) > 0
    error_message = "The scans list must be defined and not empty."
  }

  validation {
    condition = (
      alltrue([
        for scan in var.scans : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-_]+[a-zA-Z0-9])*$", scan.identifier))
      ])
    )
    error_message = "The identifier field must contain only alphanumeric characters, dashes, and underscores, and must not start or end with a dash or underscore."
  }

  validation {
    condition = (
      alltrue([
        for scan in var.scans : contains(["github", "azure_devops", "custom"], scan.scm)
      ])
    )
    error_message = "The scm field must be one of 'github', 'azure_devops', 'custom'."
  }

  validation {
    condition = (
      alltrue([
        for scan in var.scans : length(scan.credentials_reference) > 0
      ])
    )
    error_message = "Credentials reference must not be empty."
  }

  validation {
    condition = (
      alltrue([
        for scan in var.scans : scan.files == null ? true : alltrue([for file in scan.files : try(fileexists(file), false)])
      ])
    )
    error_message = "All files in the 'files' field must exist."
  }

  validation {
    condition = (
      alltrue([
        for scan in var.scans : scan.repositories_to_scan == null ? true : fileexists(scan.repositories_to_scan)
      ])
    )
    error_message = "When set, repositories_to_scan should reference an existing file on the local system."
  }

  validation {
    condition = (
      alltrue([
        for scan in var.scans : contains(jsondecode(file("../../../../../configuration/secrets-finder/aws/aws_ec2_instances.json")), scan.ec2_instance_type)
      ])
    )
    error_message = "The ec2_instance_type field must be a valid AWS EC2 instance type."
  }
}

variable "enable_datadog_monitors" {
  type        = bool
  default     = true
  description = "Define whether Datadog monitors should be set up to monitor the status of the EC2 instances and the Codebuild project. If this variable is set to 'true', both 'datadog_api_key_reference' and 'datadog_application_key_reference' variables should be set, and the corresponding secrets should exist in Parameter Store."
}

variable "datadog_account" {
  type        = string
  default     = null
  description = "The name of the Datadog account to which EC2 instance metrics should be reported and where monitors are set up. This variable is only used if 'enable_datadog_monitors' variable is set to 'true'."
}

variable "datadog_api_key_reference" {
  type        = string
  default     = null
  description = "Name of the secret stored in Secrets Manager and containing the Datadog API key. Leave empty if Datadog should not be configured."

  validation {
    condition     = (var.datadog_api_key_reference == null) || can(regex("^[a-zA-Z0-9/_+=.@-]{1,512}$", var.datadog_api_key_reference))
    error_message = "The secret name is invalid"
  }
}

variable "datadog_application_key_reference" {
  type        = string
  default     = null
  description = "Name of the secret stored in Secrets Manager and containing the Datadog application key. Leave empty if Datadog monitors should not be configured."

  validation {
    condition     = (var.datadog_application_key_reference == null) || can(regex("^[a-zA-Z0-9/_+=.@-]{1,512}$", var.datadog_application_key_reference))
    error_message = "The secret name is invalid"
  }
}

variable "datadog_monitors_notify_list" {
  type        = list(string)
  default     = []
  description = "List of recipients to notify whenever an alert is triggered. The format for each recipient should conform with the official specification (https://docs.datadoghq.com/monitors/notify/#notifications). This list is only considered if 'enable_datadog_monitors' variable is set to 'true'."
}

variable "datadog_ec2_instance_monitor_ec2_age_limit" {
  type        = number
  default     = 1
  description = "Time (in hours) to wait before considering an instance in an unhealthy state. Value should be between 1 and 72 and is only considered if 'enable_datadog_monitors' is set to 'true'."

  validation {
    condition     = var.datadog_ec2_instance_monitor_ec2_age_limit >= 1 && var.datadog_ec2_instance_monitor_ec2_age_limit <= 72
    error_message = "The value should be between 1 and 72 (hours)"
  }
}

variable "datadog_tags" {
  type        = list(string)
  default     = []
  description = "A list of tags for Datadog"
}
