resource "aws_s3_bucket" "secrets_finder" {
  bucket        = var.s3_bucket_name
  force_destroy = var.force_destroy != null ? var.force_destroy : false
}

resource "aws_s3_bucket_public_access_block" "disable_public_access" {
  bucket                  = aws_s3_bucket.secrets_finder.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.secrets_finder.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "versioning-bucket-config" {
  depends_on = [aws_s3_bucket_versioning.versioning]

  bucket = aws_s3_bucket.secrets_finder.id

  rule {
    id = "delete-non-current-versions"

    noncurrent_version_expiration {
      noncurrent_days = var.days_after_permanent_deletion_of_noncurrent_versions
    }

    status = "Enabled"
  }
}
