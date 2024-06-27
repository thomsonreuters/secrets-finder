variable "aws_region" {
  type        = string
  description = "AWS region where to deploy resources"

  validation {
    condition     = can(regex("^(af|ap|ca|eu|me|sa|us)-(central|north|(north(?:east|west))|south|south(?:east|west)|east|west)-\\d+$", var.aws_region))
    error_message = "You should enter a valid AWS region (https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html)"
  }
}

variable "aws_profile" {
  type        = string
  description = "AWS profile to use for authentication"
}

variable "environment_type" {
  type        = string
  description = "Environment type"

  validation {
    condition     = contains(["PRODUCTION", "PRE-PRODUCTION", "QUALITY ASSURANCE", "INTEGRATION TESTING", "DEVELOPMENT", "LAB"], var.environment_type)
    error_message = "The environment type should be one of the following values: PRODUCTION, PRE-PRODUCTION, QUALITY ASSURANCE, INTEGRATION TESTING, DEVELOPMENT, LAB (case sensitive)"
  }
}

variable "vpc_name" {
  type        = string
  description = "Identifier of the VPC to use for secrets-finder"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet where to deploy the resources (wildcards are allowed: first match is used)"
}

variable "db_subnet_group_name" {
  type        = string
  description = "Name of the RDS subnet group"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to the resources"

  validation {
    condition     = alltrue([for v in values(var.tags) : v != ""])
    error_message = "Tag values must not be empty."
  }
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "secrets-finder"
}

variable "permissions_boundary_arn" {
  type        = string
  description = "ARN of the permissions boundary to use for the IAM role"

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:policy\\/([a-zA-Z0-9-_.]+)$", var.permissions_boundary_arn))
    error_message = "The provided ARN is not a valid ARN for a policy"
  }
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket to create"

  validation {
    condition     = can(regex("^[a-z0-9.-]{3,63}$", var.s3_bucket_name))
    error_message = "The S3 bucket name must be a valid string with only a-z0-9.- characters and have a length between 3 and 63"
  }
}

variable "rds_username" {
  type        = string
  description = "Username for the RDS instance"
  default     = "secrets_finder"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{1,}$", var.rds_username))
    error_message = "The RDS username must be a valid string with only a-z0-9_ characters, have a length greater than 1, and not start with a number"
  }
}


variable "rds_db_name" {
  type        = string
  description = "Name of the database to create in the RDS instance"
  default     = "secrets_finder"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{1,}$", var.rds_db_name))
    error_message = "The RDS database name must be a valid string with only a-z0-9_ characters, have a length greater than 1, and not start with a number"
  }
}

variable "ingestion_schedule" {
  type        = string
  description = "Cron schedule for the CloudWatch Event Rule"
  default     = "rate(24 hours)"

  validation {
    condition     = can(regex("^(rate|cron)\\(\\d+ (minutes|hours|days)\\)$", var.ingestion_schedule))
    error_message = "The ingestion schedule should be in the format 'rate(n minutes|hours|days)' or 'cron(expression)', where n is a positive integer"
  }
}

variable "disable_ingestion_schedule" {
  type        = bool
  description = "Disable the ingestion schedule"
  default     = false
}
