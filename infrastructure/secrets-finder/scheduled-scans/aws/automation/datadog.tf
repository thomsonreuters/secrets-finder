resource "datadog_monitor" "monitor_ec2_instance_age" {
  count = var.enable_datadog_monitors == true ? 1 : 0

  name                     = "Secrets Finder: EC2 instance status"
  type                     = "metric alert"
  message                  = templatefile(local.datadog_ec2_instance_monitoring, { aws_region = var.aws_region, limit = var.datadog_ec2_instance_monitor_ec2_age_limit, notification_recipients = join(" ", var.datadog_monitors_notify_list) })
  include_tags             = false
  notify_audit             = true
  require_full_window      = false
  priority                 = 3
  timeout_h                = 1
  notification_preset_name = "hide_all"

  query = "max(last_1h):max:aws.ec2.instance_age{name:${var.project_name}-*} by {host} > ${var.datadog_ec2_instance_monitor_ec2_age_limit * 3600}"

  tags = local.datadog_tags
}

resource "datadog_monitor" "monitor_failed_builds" {
  count = var.enable_datadog_monitors == true ? 1 : 0

  name                     = "Secrets Finder: Codebuild status"
  type                     = "metric alert"
  message                  = templatefile(local.datadog_codebuild_monitoring, { aws_region = var.aws_region, aws_account_id = data.aws_caller_identity.current.account_id, notification_recipients = join(" ", var.datadog_monitors_notify_list) })
  include_tags             = false
  notify_audit             = true
  require_full_window      = false
  priority                 = 3
  no_data_timeframe        = 60
  timeout_h                = 12
  notification_preset_name = "hide_all"

  query = "sum(last_6h):max:aws.codebuild.failed_builds{projectname:${var.project_name}} by {projectname}.as_count() > 0"

  tags = local.datadog_tags
}
