locals {
  environment              = replace(lower(var.environment_type), " ", "-")
  db_url                   = "postgresql://${var.rds_username}:${random_password.rds_master_password.result}@${aws_db_instance.rds_postgres.address}"
  configuration_dir        = "${path.module}/configuration"
  ingestion_lambda_dir     = "${path.module}/lambda/ingestion"
  ingestion_lambda_archive = "${local.ingestion_lambda_dir}/ingestion.zip"
  migration_lambda_dir     = "${path.module}/lambda/migration"
  migration_lambda_archive = "${local.migration_lambda_dir}/migration.zip"
  s3_bucket_arn            = "arn:aws:s3:::${var.s3_bucket_name}"
  tags                     = var.tags
}
