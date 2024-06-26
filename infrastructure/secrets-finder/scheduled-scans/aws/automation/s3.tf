data "aws_s3_bucket" "secrets_finder" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_object" "trufflehog_configuration_file" {
  count = var.trufflehog_configuration_file != null ? 1 : 0

  bucket      = data.aws_s3_bucket.secrets_finder.id
  key         = "secrets-finder/scheduled-scans/scanner/configuration.yaml"
  content     = local.trufflehog_configuration_file
  source_hash = filemd5(local.trufflehog_configuration_file)
}

resource "aws_s3_object" "common_files" {
  count = length(local.common_files)

  bucket      = data.aws_s3_bucket.secrets_finder.id
  key         = "secrets-finder/scheduled-scans/scanner/${basename(local.common_files[count.index])}"
  content     = file(local.common_files[count.index])
  source_hash = filemd5(local.common_files[count.index])
}

resource "aws_s3_object" "scanner_static_files" {
  count = length(local.scanner_static_files)

  bucket      = data.aws_s3_bucket.secrets_finder.id
  key         = "secrets-finder/scheduled-scans/scanner/${basename(local.scanner_static_files[count.index])}"
  content     = file(local.scanner_static_files[count.index])
  source_hash = filemd5(local.scanner_static_files[count.index])
}

resource "aws_s3_object" "backend_static_files" {
  count = length(local.backend_static_files)

  bucket      = data.aws_s3_bucket.secrets_finder.id
  key         = "secrets-finder/scheduled-scans/scanner/${basename(local.backend_static_files[count.index])}"
  content     = file(local.backend_static_files[count.index])
  source_hash = filemd5(local.backend_static_files[count.index])
}

resource "aws_s3_object" "scanner_template_files" {
  count = length(local.scanner_template_files_formatted_for_all_scans)

  bucket      = data.aws_s3_bucket.secrets_finder.id
  key         = "secrets-finder/scheduled-scans/scans/${local.scanner_template_files_formatted_for_all_scans[count.index].scan.identifier}/setup/${basename(local.scanner_template_files_formatted_for_all_scans[count.index].reference)}"
  content     = local.scanner_template_files_formatted_for_all_scans[count.index].formatted_file
  source_hash = md5(local.scanner_template_files_formatted_for_all_scans[count.index].formatted_file)
}

resource "aws_s3_object" "backend_template_files" {
  count = length(local.backend_template_files_formatted_for_all_scans)

  bucket       = data.aws_s3_bucket.secrets_finder.id
  key          = "secrets-finder/scheduled-scans/scans/${local.backend_template_files_formatted_for_all_scans[count.index].scan.identifier}/setup/${basename(local.backend_template_files_formatted_for_all_scans[count.index].reference)}"
  content      = local.backend_template_files_formatted_for_all_scans[count.index].formatted_file
  source_hash  = md5(local.backend_template_files_formatted_for_all_scans[count.index].formatted_file)
  content_type = "text/plain"
}

resource "aws_s3_object" "scanning_files" {
  count = length(local.all_user_submitted_files)

  bucket      = data.aws_s3_bucket.secrets_finder.id
  key         = "secrets-finder/scheduled-scans/scans/${local.all_user_submitted_files[count.index].scan}/files/${basename(local.all_user_submitted_files[count.index].file)}"
  content     = file(local.all_user_submitted_files[count.index].file)
  source_hash = filemd5(local.all_user_submitted_files[count.index].file)

  lifecycle {
    precondition {
      condition     = contains(local.all_scanner_files_stored_in_s3_bucket, "secrets-finder/scheduled-scans/scans/${local.all_user_submitted_files[count.index].scan}/${basename(local.all_user_submitted_files[count.index].file)}") == false
      error_message = "The user-supplied file ${basename(local.all_user_submitted_files[count.index].file)} conflicts with another file used by secrets-finder."
    }
  }
}

resource "aws_s3_object" "repositories_to_scan_files" {
  count = length(local.repositories_to_scan)

  bucket      = data.aws_s3_bucket.secrets_finder.id
  key         = "secrets-finder/scheduled-scans/scans/${local.repositories_to_scan[count.index].scan}/setup/repositories_to_scan.json"
  content     = file(local.repositories_to_scan[count.index].file)
  source_hash = filemd5(local.repositories_to_scan[count.index].file)
}
