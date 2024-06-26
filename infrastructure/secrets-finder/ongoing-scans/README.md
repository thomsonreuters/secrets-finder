# Ongoing scans of GitHub repositories

<br /><br />

## Table of Contents
1. [Introduction](#introduction)
2. [Infrastructure](#infrastructure)
3. [Scanning operations](#scanning-operations)
4. [Generated reports](#generated-reports)
5. [Configuration of GitHub Workflows](#configuration-of-github-workflows)
6. [Deployment instructions](#deployment-instructions)

<br/><br/>

## Introduction
This folder holds the infrastructure for the ongoing secrets scanning solution. The system is designed for use with GitHub repositories belonging to one or more organizations. The open-source tool [TruffleHog](https://github.com/trufflesecurity/trufflehog) carries out the scanning of repositories for secrets. The tool is executed as part of GitHub workflows triggered by events received from a GitHub App.

> **NOTE:**\
> As part of the first and current release of secrets-finder, the solution relies on GitHub Enterprise Cloud (or alternatively GitHub Enterprise Server) as well as AWS. As such, the documentation below is tailored to these platforms. The maintainers of the project aim to provide support for other Source Code Management platforms and cloud providers in the next releases.

<br/><br/>

## Infrastructure
The infrastructure consists of four main key components: a GitHub App that receives events from GitHub organizations where it is deployed on and forwards them to an API Gateway REST API, which in turn sends those events to an AWS Lambda Function for processing. Once cryptographically verified, the events that are deemed in scope for scanning are passed to the GitHub workflows to carry out the secrets detection process accordingly.

### GitHub App
The GitHub App, deployed at the level of the organization, captures all pushes to repositories and actions on pull requests. It forwards these events to the API Gateway set up in AWS.

### CloudFront Distribution (and Route53 Record)
A CloudFront Distribution is used to front the API Gateway being deployed. With the chosen setup, direct calls made to the API Gateway are not allowed. Both the distribution and the REST API are protected by AWS WAF. Finally, a Route53 record can be set up to point to the domain name to the CloudFront distribution.

### API Gateway REST API
The API Gateway REST API features a single endpoint (`/production/secrets-finder`) that receives POST requests from the GitHub App and forwards them to the AWS Lambda Function set up.

> **IMPORTANT:**\
> Due to known limitations from API Gateway and GitHub Apps, requests are not authenticated at this level. Instead, we perform the verification of cryptographic signatures attached to the events within the AWS Lambda Function. While this guarantees the security of the system, DoS and cost-occurring attacks are in theory possible. The use of AWS WAF coupled with a shared secret between the CloudFront Distribution and the API Gateway aim to deter those types of attacks.

### AWS Lambda Function
The code deployed on AWS Lambda can be found in the [`lambda/secret_detection.py`](/infrastructure/secrets-finder/ongoing-scans/aws/lambda/secrets-finder.py) file. The `handler` function serves as the entry point for the Lambda.

As part of its operations, the function first verifies incoming requests transferred to it by checking the `X-Hub-Signature-256` header for a valid signature. If the signature is missing or invalid, the function returns a 401 or 403 error, respectively.

Assuming the signature is valid, the function then checks that the event is in scope for a secrets scanning (i.e., a push to the default branch of the concerned repository or a creation/update of a pull request in the reference implementation). If the event falls into the defined categories, it is forwarded to the appropriate GitHub workflow using the GitHub Actions API.

The payload of the request sent to the GitHub workflow includes the event type (`event_type`), which is used to determine which workflow to trigger. The type can be either `secret_detection_in_default_branch` or `secret_detection_in_pull_request`. The payload also includes the original information sent by GitHub in the `client_payload.event` key. This information will be used by the workflow when performing the scan.

### GitHub Workflows
Two GitHub workflows are deployed as part of the infrastructure:
- [`secret-detection-push.yaml`](/.github/workflows/secret-detection-push.yaml)
- [`secret-detection-pull-request.yaml`](/.github/workflows/secret-detection-pull-request.yaml)

Those workflows are responsible for the scanning of one or several commits pushed in the default branch of a repository – as part of a push event, or added to pull requests, respectively. They are triggered using a `repository_dispatch` event sent by the AWS Lambda Function set up.

While the AWS Lambda Function verifies the nature of the events received, the GitHub Workflows themselves check that the events fall into the expected categories before running secrets detection jobs.

The following GitHub Actions are used within the workflows:
- [`actions/checkout@v4`](https://github.com/actions/checkout)
- [`actions/github-script@v7`](https://github.com/actions/github-script)
- [`actions/upload-artifact@v4`](https://github.com/actions/upload-artifact)
- [`actions/download-artifact@v4`](https://github.com/actions/download-artifact)
- [`aws-actions/configure-aws-credentials@v4`](https://github.com/aws-actions/configure-aws-credentials)

<br/><br/>

## Scanning operations
Each workflow carries out operations that are specific to the context being considered, while the main logic remains the same across all workflows.

Contextual information is logged in the workflow run and secrets detection is performed. In the context of a push to the default branch of a repository, all commits belonging to that push are reviewed. For a pull requests, all commits since the creation of the pull request are deemed in scope for scanning, and this each time a scan is performed.

If any findings are found, the logs are parsed and display (if debug enabled). The final report is then generated and sent to the storage location specified (i.e., an S3 bucket in the reference implementation). Note that even when no findings are found, a report is generated, this to allow users to better track how their secrets detection program behave.

A list of findings is also properly formatted for direct reporting to developers. In the context a commit pushed to a default branch, issues are created and assigned to the people that have committed one or more secrets. When secrets are found in a pull request, a request for comment is added and list all the commits belonging to the pull request that contain hardcoded secrets. Note that a `leaked-secrets` tag is added automatically to concerned pull requests and issues.

When repositories are public, issues and requests for comments are only added if repositories are first made private (cf. options below). This conditional alerting mechanism aligned with "secure by default" best practices.

<br/><br/>

## Generated reports
Each time a scan is performed, a report is generated and persisted. This report contains a JSON object made of the following elements:
- `scan_type`: always `prevention` with ongoing scans
- `start`: date (in ISO format) indicating when the scan started
- `end`: date (in ISO format) indicating when the scan finished
- `status`: either `succces` if the scan could be performed, or `failure` otherwise
- `scan_mode`: `verified` if only verified secrets are reported, `all` otherwise (the number of findings reported does not influence this value)
- `scan_context`: `commit` when scanning push events made to default branches, or `pull_request` when scanning a pull request
- `scan_uuid`: unique identifier representing the scan performed
- `scan_identifier`: always `github_secrets_finder` in this context
- `scm`: always `github` in this context
- `results`: an array containing exactly one entry, as specified below

The `results` key holds an array where the single object being reported exposes the following elements:
- `scan_uuid`: the identifier representing the scan of the repository (different than `scan_uuid` field at top-level)
- `start`: same as the top-level key of the same name
- `end`: same as the top-level key of the same name
- `organization`: the name of the GitHub organization the repository belongs to
- `repository`: the name of the repository scanned
- `status`: either `success` if the scan could be performed, or `failure` otherwise (the number of findings reported does not influence this value)
- `metadata`: object containing an `identifier` key (the commit hash or pull request number, depending on the scan context), and a `created_at` key (when the commit or the pull request have been created, respectivel)
- `findings`: an array of findings as returned by TruffleHog, if any found

<br/><br/>

## Configuration of GitHub Workflows
The following GitHub variables are used within the workflows:\
(see [Deployment instructions](#deployment-instructions) for more information)
- `AWS_REGION`: the region to use when configuring the AWS client
- `AWS_ROLE_ARN`: the ARN of the role to assume when pushing results to the S3 bucket (should have put permissions)
- `AWS_S3_BUCKET_NAME`: the name of the S3 bucket where results are stored
- `SCAN_TIMEOUT_MINUTES`: how long to wait for the scanner to report results before failing the job (default is 15 minutes)
- `CUSTOM_DETECTORS_CONFIG_FILE`: the path to a custom detectors file as supported by TruffleHog (e.g., `configuration/custom_detectors.yaml`, assuming configuration is located at the root of the repository)
- `REPORT_ONLY_VERIFIED_SECRETS`: if `true`, only secrets that are verified by TruffleHog are reported, other all secrets found are enumerated (default is all)
- `HIDE_PUBLIC_REPOSITORIES_IF_SECRETS_FOUND`: if `true`, any public repository where secrets are found has its visibility changed; if the operation fails, creation of issues/requests for comments is aborted (default is false)

The following GitHub secrets are used within the workflows\
(see [Deployment instructions](#deployment-instructions) for more information)
- `ORG_TOKEN`: the token used to fetch the repository to scan, and if needed, take actions (change visibility of repository, creation of issues/requests for comments, add of label, and assignment of issues to selected users)
- `AWS_ACCESS_KEY_ID`: the access key ID of the principal to use for authentication, when assuming the role specified in `AWS_ROLE_ARN`
- `AWS_SECRET_ACCESS_KEY`; the access key secret of the principal to use for authentication, when assuming the role specified in `AWS_ROLE_ARN`

<br/><br/>

## Deployment instructions
To set up the infrastructure, please proceed with the following steps. It is assumed that the workflows have already been deployed within the repository responsible for performing the scans, in the `.github/workflows` directory. This repository can be referenced using the `${var.github_secret_prevention_workflow_org}` and `${var.github_secret_prevention_workflow_repository}` variables when deploying the infrastructure with Terraform.

### Preliminary setup for CloudFront and Route53
The API Gateway REST API is fronted by an AWS CloudFront Distribution and a Route53 Record can be requested for creation.

While the resources are deployed alongside the rest of the infrastructure, the following steps must be performed manually to configure the CloudFront Distribution properly, in case you want to use a custom SSL certificate (`${var.use_custom_certificate}` variable set to true).

When using a custom SSL certificate, the Common Name of the certificate should be `${var.endpoint}.${var.hosted_zone}`, where `${var.endpoint}` is the name of the endpoint specified and `${var.hosted_zone}` is the public hosted zone selected available in Route53, as specified in the `terraform.tfvars` file of the Terraform module.

Custom certificates should be registered in AWS Certificate Manager. Users are provided with a shell script helper (see [`pkcs12-to-pem-converter.sh`](/infrastructure/secrets-finder/ongoing-scans/aws/certificate/pkcs12-to-pem-converter.sh)) to export the required information from a certificate stored in PKCS#12 format. You can learn more about how to use the script by running the `./pkcs12-to-pem-converter.sh --help` command.

> **Warning:**\
> When using `--decrypt-private-key` option, the script will generate a `private_key_insecure.pem` file containing the private key in plain text. This file should be deleted after the certificate is registered in AWS Certificate Manager.

> **Note:**\
> Once the certificate is registered, the ARN of the certificate should be specified in the following variable of the Terraform module: `${var.certificate_arn}`

### Registration of required secrets in AWS Secrets Manager
Using the [`secrets` module](/infrastructure/secrets-finder/setup/aws/secrets), you must store:
- the GitHub token to use when forwarding events to the GitHub workflows;
the GitHub App secret used when configuring the GitHub App; and
- the Web ACL secret to authenticate requests received by the API Gateway REST API.

The reference to those secrets (i.e., the secrets names) should then be specified in the respective variables listed below:
- `${var.github_token_reference}`
- `${var.github_app_secret_reference}`
- `${var.api_gateway_web_acl_secret_reference}`

### Registration of Datadog API token in AWS Secrets Manager
You have the possibility to use Datadog for reporting on AWS Lambda activity. For this, you need to store the API key in Secrets Manager, e.g., by using the [`secrets` module](/infrastructure/secrets-finder/setup/aws/secrets) provided. Then, you should specify the `${var.datadog_api_key_reference}` variable, which represents the name of the secret stored in Secrets Manager and holding the API key to use. You should also specify the service name for Datadog (`${var.datadog_service_name}` variable).

### Deployment of the AWS infrastructure
> **Note:**\
> It is assumed that you have already [installed Terraform](https://developer.hashicorp.com/terraform/downloads) and configured your AWS credentials accordingly for the profile you want to use.

From the `lambda` folder, create a ZIP archive of the AWS Lambda Function:
```bash
chmod +x package.sh && ./package.sh -o secrets-finder.zip
```

> **Note:**\
> If using the `-o` (or `--output`) option to provide a name, ensure that the name ends with `.zip`. If no name is provided, the resulting archive will be named in the following format:\
> `secrets-finder-$${YYY-MM-DD}-$${SHORT_SHA256_LAMBDA}-$${SHORT_SHA256_REQUIREMENTS}.zip`\
> The short SHA256 are the first 8 characters of the original SHA256.

Then, navigate to the [`infrastructure/secrets-finder/ongoing-scans/aws`](/infrastructure/secrets-finder/ongoing-scans/aws) directory.

To configure the S3 backend for Terraform, modify the `s3.tfbackend` file by setting the appropriate values. Be sure to reference the correct `<aws_profile>` AWS profile in the `profile` key.

Then, initialize Terraform:
```bash
terraform init -backend-config=s3.tfbackend
```

> **IMPORTANT:**\
> To successfully deploy the infrastructure, it is assumed that the S3 Bucket holding the remote states already exists. This also holds for the DynamoDB Table listing the locks. You are responsible for the creation of such resources. We recommend reusing the same bucket and table across all modules of secrets-finder. In such case, make sure to specify a different path for each module.

Next, create a `terraform.tfvars` file and set the required variables. This file as well as the [README.md](/infrastructure/secrets-finder/ongoing-scans/aws/README.md) file provided alongside the module provide valuable information about the purpose of each variable.

Lastly, review the changes to be made and, if satisfactory, proceed with deploying the infrastructure by following the steps below:
```bash
# Review changes
terraform plan

# Deploy changes
terrafrom apply -auto-approve
```

Upon successful completion, the following outputs should be available:
- `api_gateway_url`
- `cloudwatch_logs`
- `lambda_execution_role`
- `lambda_function`
- `cloudfront_distribution`
- `route53_record` (if requested)

### Deployment and installation of the GitHub App
A GitHub App should be created and then installed at the level of the organization(s) you want to scan. The GitHub App should be configured as follows:

In the *General* tab:
- **Webhook URL**\
  `${route53_record}/secrets-finder` where `${route53_record}` is the value of the output of same name from the Terraform module. If no record should be created, then the webhook URL should be `${cloudfront_distribution_endpoint}/secrets-finder`.
- **Webhook secret**\
  The name of the secret stored in Secrets Managed and referenced in the `${var.github_app_secret_reference}` variable of the Terraform module.

In the *Permissions & events* tab, set the following permissions:
- `Contents`: Read and write
- `Metadata`: Read-only
- `Pull requests`: Read-only

In the *Permissions & events* tab, subscribe to the following events:
- `Push`
- `Pull request`

During installation in an organization, you are expected to define which repositories the GitHub App should have access to, i.e., the repositories subject for scanning.
