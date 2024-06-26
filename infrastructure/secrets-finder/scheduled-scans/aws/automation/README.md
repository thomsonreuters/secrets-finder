# automation

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_datadog"></a> [datadog](#requirement\_datadog) | ~> 3.23 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_datadog"></a> [datadog](#provider\_datadog) | ~> 3.23 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.start_codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.trigger_codebuild_start](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_codebuild_project.secrets_finder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_iam_policy.permissions_for_codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.start_codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.tag_cloudwatch_event](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cloudwatch_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codebuild_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.permissions_for_codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.start_codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.tag_event](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_object.backend_static_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.backend_template_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.common_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.repositories_to_scan_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.scanner_static_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.scanner_template_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.scanning_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.trufflehog_configuration_file](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_sns_topic.important_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.email_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [datadog_monitor.monitor_ec2_instance_age](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/monitor) | resource |
| [datadog_monitor.monitor_failed_builds](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/monitor) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cloudwatch_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_assume_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.policy_document_permissions_for_codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.policy_document_start_codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.policy_document_tag_cloudwatch_event](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.ami_encryption_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_kms_key.ebs_encryption_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_s3_bucket.secrets_finder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_secretsmanager_secret.credentials_references](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret.datadog_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret.datadog_application_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret.token_reference_github_organization_hosting_secrets_finder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.datadog_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_version.datadog_application_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_subnets.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_encryption_key_arn"></a> [ami\_encryption\_key\_arn](#input\_ami\_encryption\_key\_arn) | The ARN of the KMS key used to decrypt/encrypt the AMI used for the scanning instances | `string` | `null` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile to use for authentication | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where to deploy resources | `string` | `"us-east-1"` | no |
| <a name="input_datadog_account"></a> [datadog\_account](#input\_datadog\_account) | The name of the Datadog account to which EC2 instance metrics should be reported and where monitors are set up. This variable is only used if 'enable\_datadog\_monitors' variable is set to 'true'. | `string` | `null` | no |
| <a name="input_datadog_api_key_reference"></a> [datadog\_api\_key\_reference](#input\_datadog\_api\_key\_reference) | Name of the secret stored in Secrets Manager and containing the Datadog API key. Leave empty if Datadog should not be configured. | `string` | `null` | no |
| <a name="input_datadog_application_key_reference"></a> [datadog\_application\_key\_reference](#input\_datadog\_application\_key\_reference) | Name of the secret stored in Secrets Manager and containing the Datadog application key. Leave empty if Datadog monitors should not be configured. | `string` | `null` | no |
| <a name="input_datadog_ec2_instance_monitor_ec2_age_limit"></a> [datadog\_ec2\_instance\_monitor\_ec2\_age\_limit](#input\_datadog\_ec2\_instance\_monitor\_ec2\_age\_limit) | Time (in hours) to wait before considering an instance in an unhealthy state. Value should be between 1 and 72 and is only considered if 'enable\_datadog\_monitors' is set to 'true'. | `number` | `1` | no |
| <a name="input_datadog_monitors_notify_list"></a> [datadog\_monitors\_notify\_list](#input\_datadog\_monitors\_notify\_list) | List of recipients to notify whenever an alert is triggered. The format for each recipient should conform with the official specification (https://docs.datadoghq.com/monitors/notify/#notifications). This list is only considered if 'enable\_datadog\_monitors' variable is set to 'true'. | `list(string)` | `[]` | no |
| <a name="input_datadog_tags"></a> [datadog\_tags](#input\_datadog\_tags) | A list of tags for Datadog | `list(string)` | `[]` | no |
| <a name="input_dynamodb_table_remote_states"></a> [dynamodb\_table\_remote\_states](#input\_dynamodb\_table\_remote\_states) | Name of the DynamoDB table containing the locks used for the remote states representing the infrastructure | `string` | n/a | yes |
| <a name="input_ebs_encryption_key_arn"></a> [ebs\_encryption\_key\_arn](#input\_ebs\_encryption\_key\_arn) | The ARN of the KMS key used to encrypt the EBS volumes | `string` | `null` | no |
| <a name="input_enable_datadog_monitors"></a> [enable\_datadog\_monitors](#input\_enable\_datadog\_monitors) | Define whether Datadog monitors should be set up to monitor the status of the EC2 instances and the Codebuild project. If this variable is set to 'true', both 'datadog\_api\_key\_reference' and 'datadog\_application\_key\_reference' variables should be set, and the corresponding secrets should exist in Parameter Store. | `bool` | `true` | no |
| <a name="input_environment_type"></a> [environment\_type](#input\_environment\_type) | Environment (PRODUCTION, PRE-PRODUCTION, QUALITY ASSURANCE, INTEGRATION TESTING, DEVELOPMENT, LAB) | `string` | `"PRODUCTION"` | no |
| <a name="input_github_organization_hosting_secrets_finder"></a> [github\_organization\_hosting\_secrets\_finder](#input\_github\_organization\_hosting\_secrets\_finder) | Name of the GitHub Organization where the repository containing the secrets-finder code is hosted | `string` | n/a | yes |
| <a name="input_github_repository_hosting_secrets_finder"></a> [github\_repository\_hosting\_secrets\_finder](#input\_github\_repository\_hosting\_secrets\_finder) | Name of the GitHub Repository containing the secrets-finder code | `string` | n/a | yes |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | The path to use when creating IAM roles | `string` | `"/"` | no |
| <a name="input_instance_user"></a> [instance\_user](#input\_instance\_user) | Username to create and use on the instances started for the scanning process | `string` | `"secrets-finder"` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | The name of the IAM permissions boundary to attach to the IAM roles created by the module | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project (should be the same across all modules of secrets-finder to ensure consistency) | `string` | `"secrets-finder"` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Name of the S3 bucket containing files used for secrets detection scans | `string` | n/a | yes |
| <a name="input_s3_bucket_remote_states"></a> [s3\_bucket\_remote\_states](#input\_s3\_bucket\_remote\_states) | Name of the S3 bucket containing the remote states of the infrastructure | `string` | n/a | yes |
| <a name="input_scans"></a> [scans](#input\_scans) | List of scans to perform | <pre>list(object({<br>    identifier                    = string<br>    scm                           = string<br>    credentials_reference         = string<br>    ec2_instance_type             = string<br>    files                         = optional(list(string))<br>    repositories_to_scan          = optional(string)<br>    terminate_instance_on_error   = optional(bool)<br>    terminate_instance_after_scan = optional(bool)<br>    report_only_verified          = optional(bool)<br>  }))</pre> | n/a | yes |
| <a name="input_sns_topic_receiver"></a> [sns\_topic\_receiver](#input\_sns\_topic\_receiver) | Email address of the receiver of the SNS topic to which important notifications are sent. Leave empty if no notifications should be sent. | `string` | `null` | no |
| <a name="input_start_schedule"></a> [start\_schedule](#input\_start\_schedule) | The cron specifying when a new scanning instance should be set up (default is: every Monday at 06:00, expected format: https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html#CronExpressions) | `string` | `"cron(0 6 ? * MON *)"` | no |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Name of the subnet where to deploy the resources (wildcards are allowed: first match is used) | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to the resources | `map(string)` | `{}` | no |
| <a name="input_terraform_version"></a> [terraform\_version](#input\_terraform\_version) | Version of Terraform to use when starting a new scan from CodeBuild | `string` | `"1.8.5"` | no |
| <a name="input_token_reference_github_organization_hosting_secrets_finder"></a> [token\_reference\_github\_organization\_hosting\_secrets\_finder](#input\_token\_reference\_github\_organization\_hosting\_secrets\_finder) | Name of the secret stored in Secrets Manager containing the GitHub token for the organization hosting the secrets-finder code. Leave empty if the repository is publicly accessible. | `string` | `null` | no |
| <a name="input_trufflehog_configuration_file"></a> [trufflehog\_configuration\_file](#input\_trufflehog\_configuration\_file) | Path to the Trufflehog configuration file. Leave empty if no configuration file should be used. | `string` | `null` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Identifier of the VPC to use for secrets-finder | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_codebuild_arn"></a> [codebuild\_arn](#output\_codebuild\_arn) | n/a |
| <a name="output_event_rule_arn"></a> [event\_rule\_arn](#output\_event\_rule\_arn) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
