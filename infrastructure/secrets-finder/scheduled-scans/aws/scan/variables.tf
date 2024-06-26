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

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to the resources"
  default     = {}

  validation {
    condition     = alltrue([for v in values(var.tags) : v != ""])
    error_message = "Tag values must not be empty."
  }
}

variable "project_name" {
  type        = string
  default     = "secrets-finder"
  description = "Name of the project (should be the same across all modules of secrets-finder to ensure consistency)"
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
  description = "Identifier of the VPC to use"
}

variable "subnet_name" {
  type        = string
  description = "Identifier of the subnet where to deploy the EC2 instance"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket name where to upload the scripts"
}

variable "permissions_boundary_arn" {
  type        = string
  default     = null
  description = "The name of the IAM permissions boundary to attach to the IAM role created by the module"

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

variable "scm" {
  type        = string
  description = "SCM to use for the scan"

  validation {
    condition     = contains(["github", "azure_devops", "custom"], var.scm)
    error_message = "scm must be one of 'github', 'azure_devops', 'custom'."
  }
}

variable "scan_identifier" {
  type        = string
  description = "Identifier of the scan"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-_]+[a-zA-Z0-9])*$", var.scan_identifier))
    error_message = "scan_identifier must contain only alphanumeric characters, dashes, and underscores, and must not start or end with a dash or underscore."
  }
}

variable "credentials_reference" {
  type        = string
  description = "Name of the secret stored in Secrets Manager and containing the credentials to use for the scan"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-_]+[a-zA-Z0-9])*$", var.credentials_reference))
    error_message = "The secret name is invalid"
  }
}

variable "sns_topic_arn" {
  type        = string
  default     = null
  description = "ARN of the SNS topic to use for notifications. Leave empty if SNS notifications are not needed."

  validation {
    condition     = var.sns_topic_arn == null || can(regex("^arn:aws:sns:((af|ap|ca|eu|me|sa|us)-(central|north|(north(?:east|west))|south|south(?:east|west)|east|west)-\\d+):[0-9]{12}:([a-zA-Z0-9]([a-zA-Z0-9-_]+[a-zA-Z0-9])*)$", var.sns_topic_arn))
    error_message = "The SNS topic ARN is invalid"
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

variable "instance_type" {
  type        = string
  default     = "t3a.medium"
  description = "instance_type must be a valid AWS EC2 instance type."

  validation {
    condition     = contains(jsondecode(file("../../../../../configuration/secrets-finder/aws/aws_ec2_instances.json")), var.instance_type)
    error_message = "instance_type must be a valid AWS EC2 instance type."
  }
}

variable "instance_user" {
  type        = string
  default     = "secrets-finder"
  description = "Username to create and use on the instance started for the scanning process"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-_]+[a-zA-Z0-9])*$", var.instance_user))
    error_message = "instance_user must contain only alphanumeric characters, dashes, and underscores, and must not start or end with a dash or underscore."
  }
}

variable "existing_security_groups" {
  type        = list(string)
  default     = []
  description = "List of names representing existing security groups to add to the EC2 instance"
}

variable "new_security_groups" {
  type = list(object({
    name        = string,
    description = string,
    ingress : optional(list(object({
      from_port        = number,
      to_port          = number,
      protocol         = any,
      description      = optional(string),
      cidr_blocks      = optional(list(string), []),
      ipv6_cidr_blocks = optional(list(string), []),
      security_groups  = optional(list(string), []),
      prefix_list_ids  = optional(list(string), [])
    })), []),
    egress : optional(list(object({
      from_port        = number,
      to_port          = number,
      protocol         = any,
      description      = optional(string),
      cidr_blocks      = optional(list(string), []),
      ipv6_cidr_blocks = optional(list(string), []),
      security_groups  = optional(list(string), []),
      prefix_list_ids  = optional(list(string), [])
    })), [])
  }))

  default = []

  description = "Security groups to create (see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)"

  validation {
    condition     = alltrue([for sg in var.new_security_groups : (length(lookup(sg, "ingress", [])) != 0) || (length(lookup(sg, "egress", [])) != 0)])
    error_message = "All security groups should contain at least one ingress or egress rule"
  }

  validation {
    condition     = alltrue([for sg in var.new_security_groups : alltrue([for v in concat(lookup(sg, "ingress", []), lookup(sg, "egress", [])) : (length(lookup(v, "cidr_blocks", [])) != 0) || (length(lookup(v, "ipv6_cidr_blocks", [])) != 0) || (length(lookup(v, "security_groups", [])) != 0) || (length(lookup(v, "prefix_list_ids", [])) != 0)])])
    error_message = "All rules must define at least one of the following attributes: cidr_blocks, ipv6_cidr_blocks, security_groups, prefix_list_ids"
  }

  validation {
    condition     = alltrue([for sg in var.new_security_groups : alltrue([for v in concat(lookup(sg, "ingress", []), lookup(sg, "egress", [])) : can(regex("^((6553[0-5])|(655[0-2][0-9])|(65[0-4][0-9]{2})|(6[0-4][0-9]{3})|([1-5][0-9]{4})|([0-5]{0,5})|([0-9]{1,4}))$", v["from_port"]))])])
    error_message = "All 'from_port' values must refer to a valid port or a valid ICMP type number (see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule#from_port)"
  }

  validation {
    condition     = alltrue([for sg in var.new_security_groups : alltrue([for v in concat(lookup(sg, "ingress", []), lookup(sg, "egress", [])) : can(regex("^((6553[0-5])|(655[0-2][0-9])|(65[0-4][0-9]{2})|(6[0-4][0-9]{3})|([1-5][0-9]{4})|([0-5]{0,5})|([0-9]{1,4}))$", v["to_port"]))])])
    error_message = "All 'to_port' values must refer to a valid port or a valid ICMP type number (see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule#to_port)"
  }

  validation {
    condition     = alltrue([for sg in var.new_security_groups : alltrue([for v in concat(lookup(sg, "ingress", []), lookup(sg, "egress", [])) : can(regex("^(icmp(v6)?)|(tcp)|(udp)|(all)|((25[0-5])|(2[0-4][0-9])|(1[0-9]{2})|([1-9][0-9])|([0-9]))$", v["protocol"]))])])
    error_message = "All 'protocol' values must refer to a valid value (see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule#protocol)"
  }

  validation {
    condition     = alltrue([for sg in var.new_security_groups : alltrue([for v in concat(lookup(sg, "ingress", []), lookup(sg, "egress", [])) : v["cidr_blocks"] == null || alltrue([for address in v["cidr_blocks"] : can(regex("^((25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9]).){3}((25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9]))/(0|0?[1-9]|[12][0-9]|3[012])$", address))])])])
    error_message = "All 'cidr_blocks' should contain IP addresses denoted in CIDR format (xx.xx.xx.xx/yy)"
  }

  validation {
    condition     = alltrue([for sg in var.new_security_groups : alltrue([for v in concat(lookup(sg, "ingress", []), lookup(sg, "egress", [])) : v["ipv6_cidr_blocks"] == null || alltrue([for address in v["ipv6_cidr_blocks"] : can(regex("^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]).){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))/(([0-9])|([1-9][0-9])|(1[0-1][0-9])|(12[0-8]))$", address))])])])
    error_message = "All 'ipv6_cidr_blocks' should contain IPv6 addresses denoted in CIDR format"
  }
}

variable "trufflehog_version" {
  type        = string
  default     = "3.78.2"
  description = "Version of TruffleHog to use"
}

variable "trufflehog_processes" {
  type        = number
  default     = 20
  description = "Define the number of scanning processes that should be spawned by TruffleHog. WARNING: This may be resource intensive and consume all the host resources."

  validation {
    condition     = (var.trufflehog_processes >= 1) && (var.trufflehog_processes <= 30)
    error_message = "The number of scanning processes should be between 1 and 30 (included)"
  }
}

variable "datadog_api_key_reference" {
  type        = string
  default     = null
  description = "Name of the secret stored in Secrets Manager and containing the Datadog API key"

  validation {
    condition     = (var.datadog_api_key_reference == null) || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-_]+[a-zA-Z0-9])*$", var.datadog_api_key_reference))
    error_message = "The secret name is invalid"
  }
}

variable "datadog_enable_ec2_instance_metrics" {
  type        = bool
  default     = true
  description = "Enable the metrics for the EC2 instance in Datadog (should be 'true' if monitors are being used to track the health of the EC2 instance)"
}

variable "datadog_account" {
  type        = string
  default     = null
  description = "The name of the Datadog account to which EC2 instance metrics should be reported and where monitors are set up. This variable is only used if 'datadog_enable_ec2_instance_metrics' variable is set to 'true'."
}
