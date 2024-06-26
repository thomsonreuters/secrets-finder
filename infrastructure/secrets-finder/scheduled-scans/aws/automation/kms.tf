data "aws_kms_key" "ebs_encryption_key" {
  count  = var.ebs_encryption_key_arn != null ? 1 : 0
  key_id = var.ebs_encryption_key_arn
}

data "aws_kms_key" "ami_encryption_key" {
  count  = var.ami_encryption_key_arn != null ? 1 : 0
  key_id = var.ami_encryption_key_arn
}
