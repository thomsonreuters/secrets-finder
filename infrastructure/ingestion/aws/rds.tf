resource "aws_db_instance" "rds_postgres" {
  identifier              = "${var.project_name}-rds-postgres"
  allocated_storage       = 10
  engine                  = "postgres"
  engine_version          = "16.3"
  instance_class          = "db.t3.micro" # Smallest instance type for PostgreSQL
  username                = var.rds_username
  password                = random_password.rds_master_password.result
  parameter_group_name    = "default.postgres16"
  db_name                 = var.rds_db_name
  skip_final_snapshot     = true
  publicly_accessible     = false
  storage_encrypted       = true
  deletion_protection     = true
  backup_retention_period = 7
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = var.db_subnet_group_name
}
