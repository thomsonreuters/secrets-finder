# SCM Inventory Module

The SCM Inventory module is designed to automate the deployment of resources necessary for scanning SCM and pulling an inventory from such platforms. Initially it supports pullung GitHub organizations' repositories, their issues and pull requests to generate an inventory and maintain it.

The inventory includes by default additional information about the top 5 languages used in the repository as well as the top 5 topics used. This information can be customized to include additional data.

This Terraform module provisions an AWS EC2 instance, configures it with necessary permissions, and sets up a workflow to fetch GitHub inventory data and pushes it to an S3 bucket. The module is designed to be flexible and can be customized to support additional SCM platforms and data sources.

## Supported SCM

- GitHub: For more information see the python module [github_inventory](scripts/inventory/github_inventory/README.md) stored in this repository.

## Prerequisites
- AWS CLI configured with appropriate credentials
- Access to an AWS account with permissions to create EC2 instances, IAM roles, policies, and S3 buckets
- A GitHub token with permissions to access the repositories and organizations you wish to scan

## Usage

**Configure AWS Credentials**

Ensure your AWS CLI is configured with credentials that have the necessary permissions to create the resources defined in this module.

**Prepare GitHub Token**

Store your GitHub token in AWS Secrets Manager. Note the ARN of the secret as it will be used in the Terraform variables.

**Set Terraform Variables**

Customize the Terraform variables defined in the variables.tf file or provide a terraform.tfvars file with your specific values.

We recommend setting the variables in a terraform.tfvars file based off the [terraform.tfvars.example](infrastructure/inventory/aws/scm-inventory/deployment.tfvars.example) file provided.

Key variables include:
- aws_profile: The AWS profile to use for authentication.
- aws_region: The AWS region where resources will be deployed.
- s3_bucket_name: The name of the S3 bucket where the inventory will be stored. (This bucket must be created beforehand).
- github_token_secret_name: The ARN of the AWS Secrets Manager secret containing your GitHub token. This will have to be provisonned separately
- project_name: A name for your project.
- scanned_org: The GitHub organization you wish to scan.

**Initialize Terraform**

Run terraform init in the infrastructure/inventory/aws/scm-inventory/ directory to initialize the Terraform project.

**Apply Terraform Configuration**

Execute terraform apply to create the resources. Review the plan and confirm the action.

**Access the Inventory**

Once the EC2 instance completes its run, the generated inventory will be available in the specified S3 bucket. The instance can be configured to terminate automatically after completion.

**Additional Notes**

The EC2 instance will use a `t2.micro` instance type by default, but this can be adjusted based on your needs. We didn't want to use a larger instance type by default to avoid unnecessary costs.

It is also possible to keep the EC2 running after the inventory generation, which can be useful for debugging purposes. This can be done by setting the `terminate_instance_after_completion` variable to `false`.

The module supports optional fetching of issues and pull requests from the scanned GitHub organizations by setting the fetch_issues and fetch_pr variables.

The inventory script is located in the `scripts/inventory/github_inventory` directory.

For detailed information on the resources created and managed by this module, refer to the automatically generated documentation below.


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
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.ec2_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.permissions_for_ec2_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_access_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ec2_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.PermissionsForEC2InstancePolicyAttachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.ec2_inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_s3_object.poetry_dist](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [null_resource.poetry_build](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_ami.amazon_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.ec2_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.policy_document_permissions_for_ec2_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_access_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_s3_bucket.resources_and_results](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_secretsmanager_secret.github_token_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_security_groups.custom_security_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_groups) | data source |
| [aws_subnet.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [local_file.dist](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_image_filter"></a> [ami\_image\_filter](#input\_ami\_image\_filter) | Filter to use to find the Amazon Machine Image (AMI) to use for the EC2 instance the name can contain wildcards. Only GNU/Linux images are supported. | `string` | `"amzn2-ami-hvm*"` | no |
| <a name="input_ami_owner"></a> [ami\_owner](#input\_ami\_owner) | Owner of the Amazon Machine Image (AMI) to use for the EC2 instance | `string` | `"amazon"` | no |
| <a name="input_aws_default_security_groups_filters"></a> [aws\_default\_security\_groups\_filters](#input\_aws\_default\_security\_groups\_filters) | Filters to use to find the default security groups | `list(string)` | `[]` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile to use for authentication | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region where to deploy resources | `string` | `"us-east-1"` | no |
| <a name="input_ec2_workdir"></a> [ec2\_workdir](#input\_ec2\_workdir) | Working directory for the EC2 instance | `string` | `"~/github-inventory"` | no |
| <a name="input_environment_type"></a> [environment\_type](#input\_environment\_type) | Environment (PRODUCTION, PRE-PRODUCTION, QUALITY ASSURANCE, INTEGRATION TESTING, DEVELOPMENT, LAB) | `string` | `"PRODUCTION"` | no |
| <a name="input_fetch_issues"></a> [fetch\_issues](#input\_fetch\_issues) | Indicates whether to fetch issues for the repositories | `bool` | `false` | no |
| <a name="input_fetch_pr"></a> [fetch\_pr](#input\_fetch\_pr) | Indicates whether to fetch pull requests for the repositories | `bool` | `false` | no |
| <a name="input_github_token_secret_name"></a> [github\_token\_secret\_name](#input\_github\_token\_secret\_name) | SSM parameter name containing the GitHub token of the Service Account | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type to use for fetching the inventory | `string` | `"t2.micro"` | no |
| <a name="input_inventory_project_dir"></a> [inventory\_project\_dir](#input\_inventory\_project\_dir) | Path to the directory containing the inventory project | `string` | `"../../../../scripts/inventory/github_inventory"` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | Permissions boundary to use for the IAM role | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | `"secrets-detection"` | no |
| <a name="input_project_version"></a> [project\_version](#input\_project\_version) | Version of the project | `string` | `"0.1.0"` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | S3 bucket name where to upload the scripts and results | `string` | n/a | yes |
| <a name="input_scanned_org"></a> [scanned\_org](#input\_scanned\_org) | Name of the organization to scan | `string` | n/a | yes |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Filter to select the subnet to use, this can use wildcards. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to the resources | `map(string)` | `{}` | no |
| <a name="input_terminate_instance_after_completion"></a> [terminate\_instance\_after\_completion](#input\_terminate\_instance\_after\_completion) | Indicates whether the instance should be terminated once the scan has finished (set to false for debugging purposes) | `bool` | `true` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Filter to select the VPC to use, this can use wildcards. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_instance_arn"></a> [ec2\_instance\_arn](#output\_ec2\_instance\_arn) | n/a |
| <a name="output_ec2_instance_id"></a> [ec2\_instance\_id](#output\_ec2\_instance\_id) | n/a |
| <a name="output_ec2_role_arn"></a> [ec2\_role\_arn](#output\_ec2\_role\_arn) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
