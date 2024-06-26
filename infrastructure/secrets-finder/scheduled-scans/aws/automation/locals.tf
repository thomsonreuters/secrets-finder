locals {
  backend = "aws"

  environment = replace(lower(var.environment_type), " ", "-")
  tags        = merge(try(var.tags, {}), { environment = local.environment })

  buildspec_file                  = "codebuild-buildspec.yml"
  datadog_ec2_instance_monitoring = "datadog-ec2-monitoring"
  datadog_codebuild_monitoring    = "datadog-codebuild-monitoring"

  setup_variables = {
    aws_region                = var.aws_region
    s3_bucket                 = var.s3_bucket_name
    sns_topic_arn             = var.sns_topic_receiver != null ? aws_sns_topic.important_notifications[0].arn : ""
    instance_user             = var.instance_user
    scanner_folder            = "/home/${var.instance_user}/scanner"
    scan_folder               = "/home/${var.instance_user}/scan"
    datadog_api_key_reference = var.datadog_api_key_reference
  }

  trufflehog_configuration_file = var.trufflehog_configuration_file != null ? file(var.trufflehog_configuration_file) : null

  configuration_folder = "../../../../../configuration/secrets-finder"

  common_files = [
    "${local.configuration_folder}/common.py",
    "${local.configuration_folder}/common.requirements.txt"
  ]

  scanner_static_files = [
    "${local.configuration_folder}/scanner/git-credentials-helper.sh",
    "${local.configuration_folder}/scanner/scan-configuration.schema.json",
    "${local.configuration_folder}/scanner/scanner.py",
    "${local.configuration_folder}/scanner/scanner.requirements.txt"
  ]

  backend_static_files = [
    "${local.configuration_folder}/${local.backend}/initializer.py",
    "${local.configuration_folder}/${local.backend}/finalizer.py",
    "${local.configuration_folder}/${local.backend}/backend.py",
    "${local.configuration_folder}/${local.backend}/backend.requirements.txt"
  ]

  scanner_template_files = [
    "${local.configuration_folder}/scanner/scanner.env",
    "${local.configuration_folder}/scanner/scanner.service"
  ]

  scanner_template_files_formatted_for_all_scans = flatten([
    for s in var.scans : [
      for f in local.scanner_template_files : {
        scan      = s
        reference = f
        formatted_file = templatefile(f, merge(local.setup_variables, {
          scm                   = s.scm
          scan_identifier       = s.identifier
          credentials_reference = s.credentials_reference
          report_only_verified  = s.report_only_verified != null ? s.report_only_verified : false
        }))
      }
    ]
  ])

  backend_template_files = [
    "${local.configuration_folder}/${local.backend}/setup.sh",
    "${local.configuration_folder}/${local.backend}/backend.env"
  ]

  backend_template_files_formatted_for_all_scans = flatten([
    for s in var.scans : [
      for f in local.backend_template_files : {
        scan      = s
        reference = f
        formatted_file = templatefile(f, merge(local.setup_variables, {
          scm                           = s.scm
          scan_identifier               = s.identifier
          credentials_reference         = s.credentials_reference
          terminate_instance_on_error   = s.terminate_instance_on_error != null ? s.terminate_instance_on_error : ""
          terminate_instance_after_scan = s.terminate_instance_after_scan != null ? s.terminate_instance_after_scan : ""
          report_only_verified          = s.report_only_verified != null ? s.report_only_verified : false
        }))
      }
    ]
  ])

  all_user_submitted_files = flatten([
    for s in var.scans :
    s.files != null ? [
      for f in s.files : {
        scan = s.identifier
        file = f
      }
    ] : []
  ])

  repositories_to_scan = [
    for s in var.scans : {
      scan = s.identifier
      file = s.repositories_to_scan
    } if s.repositories_to_scan != null
  ]

  all_scanner_files_stored_in_s3_bucket = concat(
    [for f in local.common_files : "secrets-finder/scheduled-scans/scanner/${basename(f)}"],
    [for f in local.scanner_static_files : "secrets-finder/scheduled-scans/scanner/${basename(f)}"],
    [for f in local.backend_static_files : "secrets-finder/scheduled-scans/scanner/${basename(f)}"],
    [for f in local.scanner_template_files_formatted_for_all_scans : "secrets-finder/scheduled-scans/scans/${f.scan.identifier}/${basename(f.reference)}"],
    [for f in local.backend_template_files_formatted_for_all_scans : "secrets-finder/scheduled-scans/scans/${f.scan.identifier}/${basename(f.reference)}"]
  )

  all_credentials_references = [for s in var.scans : s.credentials_reference]

  datadog_tags = concat(var.datadog_tags, [var.project_name])
}
