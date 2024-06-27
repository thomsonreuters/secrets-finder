markdown
# Secrets Finder

![Contributor Covenant Badge 2.1](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)

Welcome to the Secrets Finder project! This repository contains tools and infrastructure to support organizations in rolling out their own secrets detection and prevention programs, focusing on scanning source code repositories. Our solution leverages various open-source tools and cloud services to provide automated, scheduled, and event-based scanning capabilities.

## Overview

Secrets Finder is designed to help organizations manage and detect secrets in their codebases. The project includes modules for both ongoing and scheduled scans, utilizing tools like [TruffleHog](https://github.com/trufflesecurity/trufflehog) and cloud providers such as AWS, with some features integrated with GitHub.

> **Note**: This project is a work in progress and is production-ready for the currently supported technologies. We are actively working on adding support for more integrations with cloud providers and source code management (SCM) systems. We welcome contributions and feedback from the community.

Some of the tools can be used directly from a workstation, while others require cloud infrastructure to be set up. The project includes Terraform scripts to automate the deployment of the necessary infrastructure.

### Key Features:
- **Secrets Management and Storage**: Manages secrets using AWS Secrets Manager and S3 for secure storage and access. For more details, see [Secrets Management README](infrastructure/secrets-finder/setup/aws/secrets/README.md) and [Storage README](infrastructure/secrets-finder/setup/aws/storage/README.md).
- **Database Migrations**: Manages database migrations using Alembic for SQLite, Postgres, MariaDB, and others. This component handles database schema updates, allowing for safe schema extensions. For more details, see [Migrations README](migrations/README.md).
- **Ingestion Infrastructure**: Sets up infrastructure for data ingestion using AWS services to ingest data from various sources such as scans, jobs, findings, inventory, and issues. For more details, see [Ingestion Infrastructure README](infrastructure/ingestion/aws/README.md).
- **Ongoing Scans**: Provides infrastructure for ongoing scans of GitHub repositories. This uses various components such as a GitHub Apps, an API Gateway, AWS Lambdas, and CloudFront. This type of scan monitors events in your GitHub repositories and, in the event of a secret detection, will comment on the pull request, or create an issue for pushes to the default branch. For public repositories, the visibility of the repository could aslo be changed automatically. For more details, see [Ongoing Scans README](infrastructure/secrets-finder/ongoing-scans/README.md).
- **Scheduled Scans**: Provides infrastructure for scheduled scans of git-based repositories, supporting multiple SCM platforms. This helps you scan your repositories regularly and ingests the findings allowing you to establish the baseline for your program. For more details, see [Scheduled Scans README](infrastructure/secrets-finder/scheduled-scans/aws/README.md).
- **Automated SCM Inventory**: Supports the deployment of resources to fetch your SCM inventory which includes various metadata for a repository as well as issues, pull requests, languages and topics. This lays the ground for, e.g., more efficient scheduled scanning by supporting incremental scans and only scan repositories changed. For more details, see [SCM Inventory README](infrastructure/inventory/aws/scm-inventory/README.md) and For more details, see [GitHub Inventory README](scripts/inventory/github_inventory/README.md).

## Getting Started

### Prerequisites
- Access to an AWS principal with permissions to create necessary resources (see individual modules for details)
- SCM token with required permissions for accessing repositories during scans

### Usage

While a Readme file is provided for each module with more detailed instructions on how to each module, here are some of the general steps to get started:

1. **Configure AWS Credentials**: Ensure your AWS CLI is configured with credentials that have the necessary permissions.
2. **Prepare your SCM tokens**: Either store directly the SCM secrets (GitHub or other SCM tokens) in AWS Secrets Manager. Or use the secrets module to manage and expose them to the various automation pieces.
3. **Create a Terraform State S3 Bucket**: Create an S3 bucket to store the various modules' state files and update the `s3.tfbackend` files in each module.
4. **Set Terraform Variables**: Provide a `terraform.tfvars` file setting the required variables or customizing some of the default values provided.
Provides infrastructure for scheduled scans of git-based repositories.


## Contributing

We welcome contributions! Please see our [Contributing Guidelines](docs/CONTRIBUTING.md) for more information on how to get involved.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you have any questions or need help, please use the feel free to open an issue or contact the maintainers.
