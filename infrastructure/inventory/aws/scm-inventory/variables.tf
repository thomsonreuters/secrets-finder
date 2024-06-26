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
  description = "AWS profile to use for authentication"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "secrets-detection"
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

variable "vpc_name" {
  type        = string
  default     = ""
  description = "Filter to select the VPC to use, this can use wildcards."
}

variable "subnet_name" {
  type        = string
  default     = null
  description = "Filter to select the subnet to use, this can use wildcards."
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket name where to upload the scripts and results"

  validation {
    condition     = can(regex("^[a-z0-9.-]{3,63}$", var.s3_bucket_name))
    error_message = "The S3 bucket name must be a valid string with only a-z0-9.- characters and have a length between 3 and 63"
  }
}

variable "github_token_secret_name" {
  type        = string
  description = "SSM parameter name containing the GitHub token of the Service Account"
}


variable "scanned_org" {
  type        = string
  description = "Name of the organization to scan"
}

variable "terminate_instance_after_completion" {
  type        = bool
  default     = true
  description = "Indicates whether the instance should be terminated once the scan has finished (set to false for debugging purposes)"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "Instance type to use for fetching the inventory"
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

variable "ami_owner" {
  type        = string
  default     = "amazon"
  description = "Owner of the Amazon Machine Image (AMI) to use for the EC2 instance"
}


variable "ami_image_filter" {
  type        = string
  default     = "amzn2-ami-hvm*"
  description = "Filter to use to find the Amazon Machine Image (AMI) to use for the EC2 instance the name can contain wildcards. Only GNU/Linux images are supported."

}


variable "permissions_boundary_arn" {
  type        = string
  default     = null
  description = "Permissions boundary to use for the IAM role"
}


variable "ec2_workdir" {
  type        = string
  default     = "~/github-inventory"
  description = "Working directory for the EC2 instance"
}

variable "aws_default_security_groups_filters" {
  type        = list(string)
  default     = []
  description = "Filters to use to find the default security groups"
}


variable "project_version" {
  type        = string
  default     = "0.1.0"
  description = "Version of the project"
}

variable "inventory_project_dir" {
  type        = string
  default     = "../../../../scripts/inventory/github_inventory"
  description = "Path to the directory containing the inventory project"

}

variable "fetch_pr" {
  type        = bool
  default     = false
  description = "Indicates whether to fetch pull requests for the repositories"
}

variable "fetch_issues" {
  type        = bool
  default     = false
  description = "Indicates whether to fetch issues for the repositories"

}
