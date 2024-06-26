data "aws_s3_bucket" "secrets_finder" {
  bucket = var.s3_bucket_name
}

data "aws_s3_object" "setup" {
  bucket = data.aws_s3_bucket.secrets_finder.id
  key    = "secrets-finder/scheduled-scans/scans/${var.scan_identifier}/setup/setup.sh"
}
