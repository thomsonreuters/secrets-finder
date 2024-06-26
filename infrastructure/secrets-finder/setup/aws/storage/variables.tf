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
  description = "The name of the IAM permissions boundary to attach to the IAM role created by the module (if 'create_access_role' is set to true)"

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

variable "create_access_role" {
  type        = bool
  default     = true
  description = "Whether to create an IAM role for accessing the S3 bucket"
}

variable "principals_authorized_to_access_bucket" {
  type        = list(string)
  description = "List of AWS account IDs or ARNs that are authorized to assume the role created by the module"

  validation {
    condition     = alltrue([for v in var.principals_authorized_to_access_bucket : can(regex("^(\\d{12}|(arn:aws:iam::(\\d{12})?:(role|user)((\\/)|(\\/[\\w+=,.@-]{1,128}\\/))[\\w+=,.@-]{1,128}))$", v))])
    error_message = "One or more provided values are not a valid AWS account ID or ARN"
  }

  validation {
    condition     = length(var.principals_authorized_to_access_bucket) > 0
    error_message = "At least one principal must be specified."
  }
}

variable "create_push_role" {
  type        = bool
  default     = true
  description = "Whether to create an IAM role for accessing the S3 bucket"
}

variable "principals_authorized_to_push_to_bucket" {
  type        = list(string)
  description = "List of AWS account IDs or ARNs that are authorized to assume the role created by the module"

  validation {
    condition     = alltrue([for v in var.principals_authorized_to_push_to_bucket : can(regex("^(\\d{12}|(arn:aws:iam::(\\d{12})?:(role|user)((\\/)|(\\/[\\w+=,.@-]{1,128}\\/))[\\w+=,.@-]{1,128}))$", v))])
    error_message = "One or more provided values are not a valid AWS account ID or ARN"
  }

  validation {
    condition     = length(var.principals_authorized_to_push_to_bucket) > 0
    error_message = "At least one principal must be specified."
  }
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket name where to upload the scripts"
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. WARNING: Setting this to true will permanently delete all objects in the bucket when Terraform needs to destroy the resource."
}

variable "days_after_permanent_deletion_of_noncurrent_versions" {
  type        = number
  default     = 90
  description = "Number of days after permanent deletion of noncurrent versions"

  validation {
    condition     = var.days_after_permanent_deletion_of_noncurrent_versions >= 1
    error_message = "The number of days after permanent deletion of noncurrent versions should be greater than or equal to 1"
  }
}
