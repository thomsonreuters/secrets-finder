# storage

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
| [aws_iam_policy.s3_access_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_push_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.s3_push](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.allow_access_to_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.allow_push_to_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.secrets_finder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.versioning-bucket-config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_public_access_block.disable_public_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_versioning.versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.s3_access_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_access_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_push_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_push_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile to use for authentication | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where to deploy resources | `string` | `"us-east-1"` | no |
| <a name="input_create_access_role"></a> [create\_access\_role](#input\_create\_access\_role) | Whether to create an IAM role for accessing the S3 bucket | `bool` | `true` | no |
| <a name="input_create_push_role"></a> [create\_push\_role](#input\_create\_push\_role) | Whether to create an IAM role for accessing the S3 bucket | `bool` | `true` | no |
| <a name="input_days_after_permanent_deletion_of_noncurrent_versions"></a> [days\_after\_permanent\_deletion\_of\_noncurrent\_versions](#input\_days\_after\_permanent\_deletion\_of\_noncurrent\_versions) | Number of days after permanent deletion of noncurrent versions | `number` | `90` | no |
| <a name="input_environment_type"></a> [environment\_type](#input\_environment\_type) | Environment (PRODUCTION, PRE-PRODUCTION, QUALITY ASSURANCE, INTEGRATION TESTING, DEVELOPMENT, LAB) | `string` | `"PRODUCTION"` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed without error. WARNING: Setting this to true will permanently delete all objects in the bucket when Terraform needs to destroy the resource. | `bool` | `false` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | The path to use when creating IAM roles | `string` | `"/"` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | The name of the IAM permissions boundary to attach to the IAM role created by the module (if 'create\_access\_role' is set to true) | `string` | `null` | no |
| <a name="input_principals_authorized_to_access_bucket"></a> [principals\_authorized\_to\_access\_bucket](#input\_principals\_authorized\_to\_access\_bucket) | List of AWS account IDs or ARNs that are authorized to assume the role created by the module | `list(string)` | n/a | yes |
| <a name="input_principals_authorized_to_push_to_bucket"></a> [principals\_authorized\_to\_push\_to\_bucket](#input\_principals\_authorized\_to\_push\_to\_bucket) | List of AWS account IDs or ARNs that are authorized to assume the role created by the module | `list(string)` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project (should be the same across all modules of secrets-finder to ensure consistency) | `string` | `"secrets-finder"` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | S3 bucket name where to upload the scripts | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_s3_access_role"></a> [s3\_access\_role](#output\_s3\_access\_role) | n/a |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | ARN of the S3 bucket used for secrets-finder |
| <a name="output_s3_push_role"></a> [s3\_push\_role](#output\_s3\_push\_role) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
