resource "aws_instance" "secrets_finder" {
  ami                    = data.aws_ami.amazon_ami.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.selected.ids[0]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  vpc_security_group_ids = concat([for sg in data.aws_security_group.existing_security_groups : sg.id], [for sg in aws_security_group.new_security_groups : sg.id])

  user_data_replace_on_change = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = data.aws_s3_object.setup.body

  tags = merge(
    {
      Name = "${var.project_name}-${var.scan_identifier}"
    },
    [
      (var.datadog_enable_ec2_instance_metrics == true) ? { datadog-account = var.datadog_account } : null
    ]...
  )

  lifecycle {
    precondition {
      condition     = (var.datadog_enable_ec2_instance_metrics == false) || (var.datadog_enable_ec2_instance_metrics == true && var.datadog_account != null)
      error_message = "EC2 instance metrics should be enabled but no Datadog account was provided (variable 'datadog_account' has no value)"
    }
  }

  depends_on = [
    aws_iam_policy.permissions_for_ec2_instance,
    aws_iam_role_policy_attachment.permissions_for_ec2_instance
  ]
}
