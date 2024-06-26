# aws

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
| [aws_api_gateway_deployment.production](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_integration.github_app_event_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_method.post](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_settings.log_setting](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_resource.secrets_finder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.production](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_cloudfront_distribution.distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudwatch_log_group.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.waf_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.policy_for_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda_execution_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.github_app_event_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.api_gateway_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_route53_record.record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_wafv2_web_acl.api_gateway_web_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl.cloudfront_web_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.api_gateway_web_acl_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_wafv2_web_acl_logging_configuration.api_gateway_web_acl_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration) | resource |
| [aws_wafv2_web_acl_logging_configuration.cloudfront_web_acl_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_cloudwatch_log_group.existing_waf_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudwatch_log_group) | data source |
| [aws_iam_policy_document.lambda_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.permissions_for_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.hosted_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_secretsmanager_secret.api_gateway_web_acl_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret.datadog_api_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret.github_app_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret.github_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.api_gateway_web_acl_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_gateway_web_acl_secret_reference"></a> [api\_gateway\_web\_acl\_secret\_reference](#input\_api\_gateway\_web\_acl\_secret\_reference) | Name of the secret stored in Secrets Manager and containing the secret to use for the configuration of the web ACL of the API Gateway | `string` | n/a | yes |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile to use for authentication | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where to deploy resources | `string` | `"us-east-1"` | no |
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ARN of the ACM certificate to use for the CloudFront distribution when 'use\_custom\_certificate' variable is true | `string` | n/a | yes |
| <a name="input_create_route53_record"></a> [create\_route53\_record](#input\_create\_route53\_record) | Wether to create a Route53 record for the CloudFront distribution | `bool` | `true` | no |
| <a name="input_create_waf_log_group"></a> [create\_waf\_log\_group](#input\_create\_waf\_log\_group) | Whether to create a log group for the WAF logs | `bool` | `true` | no |
| <a name="input_datadog_api_key_reference"></a> [datadog\_api\_key\_reference](#input\_datadog\_api\_key\_reference) | Name of the secret stored in Secrets Manager and containing the Datadog API token. Leave empty if Datadog should not be used. | `string` | `null` | no |
| <a name="input_datadog_service_name"></a> [datadog\_service\_name](#input\_datadog\_service\_name) | Name of the service to use for Datadog monitoring. Leave empty if Datadog should not be used. | `string` | `null` | no |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | Endpoint to use for the CloudFront distribution and Route53 record (if created) (note: 'hosted\_zone' variable will be appended to the endpoint to create the full domain name) | `string` | n/a | yes |
| <a name="input_environment_type"></a> [environment\_type](#input\_environment\_type) | Environment type | `string` | `"PRODUCTION"` | no |
| <a name="input_github_app_secret_reference"></a> [github\_app\_secret\_reference](#input\_github\_app\_secret\_reference) | Name of the secret stored in Secrets Manager and containing the secret configured for the GitHub App and used for validating signature of incoming requests | `string` | n/a | yes |
| <a name="input_github_secret_prevention_workflow_org"></a> [github\_secret\_prevention\_workflow\_org](#input\_github\_secret\_prevention\_workflow\_org) | Name of the GitHub organization where the secret prevention workflows will be triggered | `string` | n/a | yes |
| <a name="input_github_secret_prevention_workflow_repository"></a> [github\_secret\_prevention\_workflow\_repository](#input\_github\_secret\_prevention\_workflow\_repository) | Name of the GitHub repository where the secret prevention workflow will be triggered | `string` | n/a | yes |
| <a name="input_github_token_reference"></a> [github\_token\_reference](#input\_github\_token\_reference) | Name of the secret stored in Secrets Manager and containing the GitHub token to use for triggering the GitHub workflow | `string` | n/a | yes |
| <a name="input_hosted_zone"></a> [hosted\_zone](#input\_hosted\_zone) | The hosted zone to use for the CloudFront distribution | `string` | n/a | yes |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | The path to use when creating IAM roles | `string` | `"/"` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS key ARN used to encrypt the log groups. Leave empty if logs should not be encrypted. | `string` | `null` | no |
| <a name="input_lambda_archive_file_path"></a> [lambda\_archive\_file\_path](#input\_lambda\_archive\_file\_path) | Path to the archive file containing the Lambda function code | `string` | n/a | yes |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | The name of the IAM permissions boundary to attach to the IAM role created by the module | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project (should be the same across all modules of secrets-finder to ensure consistency) | `string` | `"secrets-finder"` | no |
| <a name="input_route53_record_name"></a> [route53\_record\_name](#input\_route53\_record\_name) | Name of the Route53 record to create when 'create\_route53\_record' is true | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to the resources | `map(string)` | `{}` | no |
| <a name="input_use_custom_certificate"></a> [use\_custom\_certificate](#input\_use\_custom\_certificate) | Whether to use a custom certificate for the CloudFront distribution | `bool` | `true` | no |
| <a name="input_waf_log_group_name"></a> [waf\_log\_group\_name](#input\_waf\_log\_group\_name) | Name of the log group to use for the WAF logs (if 'create\_waf\_log\_group' is true, name is used to create the log group) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_gateway_url"></a> [api\_gateway\_url](#output\_api\_gateway\_url) | n/a |
| <a name="output_cloudfront_distribution"></a> [cloudfront\_distribution](#output\_cloudfront\_distribution) | n/a |
| <a name="output_cloudwatch_logs"></a> [cloudwatch\_logs](#output\_cloudwatch\_logs) | n/a |
| <a name="output_lambda_execution_role"></a> [lambda\_execution\_role](#output\_lambda\_execution\_role) | n/a |
| <a name="output_lambda_function"></a> [lambda\_function](#output\_lambda\_function) | n/a |
| <a name="output_route53_record"></a> [route53\_record](#output\_route53\_record) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
