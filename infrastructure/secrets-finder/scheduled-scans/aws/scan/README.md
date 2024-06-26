# scan

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.ec2_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.permissions_for_ec2_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ec2_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.permissions_for_ec2_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.secrets_finder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.new_security_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.amazon_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.ec2_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.policy_document_permissions_for_ec2_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_s3_bucket.secrets_finder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_s3_object.setup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_object) | data source |
| [aws_secretsmanager_secret.credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret.datadog_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_security_group.existing_security_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_subnets.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_image_filter"></a> [ami\_image\_filter](#input\_ami\_image\_filter) | Filter to use to find the Amazon Machine Image (AMI) to use for the EC2 instance the name can contain wildcards. Only GNU/Linux images are supported. | `string` | `"amzn2-ami-hvm*"` | no |
| <a name="input_ami_owner"></a> [ami\_owner](#input\_ami\_owner) | Owner of the Amazon Machine Image (AMI) to use for the EC2 instance | `string` | `"amazon"` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile to use for authentication | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where to deploy resources | `string` | `"us-east-1"` | no |
| <a name="input_credentials_reference"></a> [credentials\_reference](#input\_credentials\_reference) | Name of the secret stored in Secrets Manager and containing the credentials to use for the scan | `string` | n/a | yes |
| <a name="input_datadog_account"></a> [datadog\_account](#input\_datadog\_account) | The name of the Datadog account to which EC2 instance metrics should be reported and where monitors are set up. This variable is only used if 'datadog\_enable\_ec2\_instance\_metrics' variable is set to 'true'. | `string` | `null` | no |
| <a name="input_datadog_api_key_reference"></a> [datadog\_api\_key\_reference](#input\_datadog\_api\_key\_reference) | Name of the secret stored in Secrets Manager and containing the Datadog API key | `string` | `null` | no |
| <a name="input_datadog_enable_ec2_instance_metrics"></a> [datadog\_enable\_ec2\_instance\_metrics](#input\_datadog\_enable\_ec2\_instance\_metrics) | Enable the metrics for the EC2 instance in Datadog (should be 'true' if monitors are being used to track the health of the EC2 instance) | `bool` | `true` | no |
| <a name="input_environment_type"></a> [environment\_type](#input\_environment\_type) | Environment (PRODUCTION, PRE-PRODUCTION, QUALITY ASSURANCE, INTEGRATION TESTING, DEVELOPMENT, LAB) | `string` | `"PRODUCTION"` | no |
| <a name="input_existing_security_groups"></a> [existing\_security\_groups](#input\_existing\_security\_groups) | List of names representing existing security groups to add to the EC2 instance | `list(string)` | `[]` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | The path to use when creating IAM roles | `string` | `"/"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | instance\_type must be a valid AWS EC2 instance type. | `string` | `"t3a.medium"` | no |
| <a name="input_instance_user"></a> [instance\_user](#input\_instance\_user) | Username to create and use on the instance started for the scanning process | `string` | `"secrets-finder"` | no |
| <a name="input_new_security_groups"></a> [new\_security\_groups](#input\_new\_security\_groups) | Security groups to create (see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | <pre>list(object({<br>    name        = string,<br>    description = string,<br>    ingress : optional(list(object({<br>      from_port        = number,<br>      to_port          = number,<br>      protocol         = any,<br>      description      = optional(string),<br>      cidr_blocks      = optional(list(string), []),<br>      ipv6_cidr_blocks = optional(list(string), []),<br>      security_groups  = optional(list(string), []),<br>      prefix_list_ids  = optional(list(string), [])<br>    })), []),<br>    egress : optional(list(object({<br>      from_port        = number,<br>      to_port          = number,<br>      protocol         = any,<br>      description      = optional(string),<br>      cidr_blocks      = optional(list(string), []),<br>      ipv6_cidr_blocks = optional(list(string), []),<br>      security_groups  = optional(list(string), []),<br>      prefix_list_ids  = optional(list(string), [])<br>    })), [])<br>  }))</pre> | `[]` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | The name of the IAM permissions boundary to attach to the IAM role created by the module | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project (should be the same across all modules of secrets-finder to ensure consistency) | `string` | `"secrets-finder"` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | S3 bucket name where to upload the scripts | `string` | n/a | yes |
| <a name="input_scan_identifier"></a> [scan\_identifier](#input\_scan\_identifier) | Identifier of the scan | `string` | n/a | yes |
| <a name="input_scm"></a> [scm](#input\_scm) | SCM to use for the scan | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | ARN of the SNS topic to use for notifications. Leave empty if SNS notifications are not needed. | `string` | `null` | no |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Identifier of the subnet where to deploy the EC2 instance | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to the resources | `map(string)` | `{}` | no |
| <a name="input_trufflehog_processes"></a> [trufflehog\_processes](#input\_trufflehog\_processes) | Define the number of scanning processes that should be spawned by TruffleHog. WARNING: This may be resource intensive and consume all the host resources. | `number` | `20` | no |
| <a name="input_trufflehog_version"></a> [trufflehog\_version](#input\_trufflehog\_version) | Version of TruffleHog to use | `string` | `"3.78.2"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Identifier of the VPC to use | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_instance_arn"></a> [ec2\_instance\_arn](#output\_ec2\_instance\_arn) | n/a |
| <a name="output_ec2_instance_id"></a> [ec2\_instance\_id](#output\_ec2\_instance\_id) | n/a |
| <a name="output_ec2_role_arn"></a> [ec2\_role\_arn](#output\_ec2\_role\_arn) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
