# Ingestion

This directory contains data ingestion lambda. The Lambda is invoked by a Step Function.

The packaging process uses the Poetry Lambda plugin and Docker to generate Lambda packages for the correct platform. This is automated when applying Terraform.

Lambda takes a set of actions as input. Each action performs a specific function.

## Lambda Actions

- `list_files` : This action list files in a S3 bucket at a give prefix
  Example:
  ```json
  {
    "action": "list_files",
    "prefix": "secrets-finder/scheduled-scans/results/"
  }
  ```
- `ingest_findings` : This action read a given `.json` file and create new records in `findings`, `scans` and `jobs` table. Corresponding file is deleted from S3 on successful ingestion
  Example:
  ```json
  {
    "action": "ingest_findings",
    "file_key": "secrets-finder/scheduled-scans/results/7eb4d1ab-ac6a-4b84-a18d-4bd944d4ef2a.json"
  }
  ```

## Add New Ingestion

Creating a new ingestion is a 4 step process.

1. Create necessary DB migration version under `migrations` directory. Refer [Create New Revisions](../../../../../migrations/README.md#creating-new-revision)
2. Create a new ingestion script under `modules` directory.
3. Register new ingestion with an action in `ingestion.py` under `ingestion_callback_mapping`
4. Add a new branch in [step function definition](../../configuration/ingestion_sfn_definition.json).

Use `terraform apply` to build and deploy the Lambda. Once deployed, the next Step Function invocation will automatically trigger the new ingestion.
