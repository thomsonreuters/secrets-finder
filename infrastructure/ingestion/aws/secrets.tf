resource "random_password" "rds_master_password" {
  length           = 40
  special          = true
  min_special      = 5
  override_special = "!#$%^&*()-_=+[]{}<>:?"
  keepers = {
    pass_version = 1
  }
}

resource "aws_secretsmanager_secret" "rds_master_password" {
  name        = "${var.project_name}-rds-master-password"
  description = "Master password for RDS instance"
}

resource "aws_secretsmanager_secret_version" "rds_master_password" {
  secret_id     = aws_secretsmanager_secret.rds_master_password.id
  secret_string = random_password.rds_master_password.result
}
