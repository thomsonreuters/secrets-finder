
resource "aws_instance" "ec2_inventory" {
  ami                         = data.aws_ami.amazon_ami.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.selected.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  security_groups             = length(var.aws_default_security_groups_filters) > 0 ? data.aws_security_groups.custom_security_groups[0].ids : [data.aws_security_group.default[0].id]
  user_data_replace_on_change = true
  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size           = 30
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = join("\n", [
    "#!/bin/bash",
    "aws configure set region ${var.aws_region}",
    "mkdir -p ${var.ec2_workdir}/github_inventory-${var.project_version}",
    "aws s3 cp s3://${data.aws_s3_bucket.resources_and_results.id}/${aws_s3_object.poetry_dist.key} ${var.ec2_workdir}/",
    "export GITHUB_INVENTORY_TOKEN=$(aws secretsmanager get-secret-value --secret-id ${data.aws_secretsmanager_secret.github_token_secret.arn} --query SecretString --output text)",
    "tar -xvf ${var.ec2_workdir}/github_inventory-${var.project_version}.tar.gz -C ${var.ec2_workdir}",
    "cd ${var.ec2_workdir}/github_inventory-${var.project_version}",
    "virtualenv local",
    "source local/bin/activate",
    "pip3 install poetry",
    "poetry lock && poetry install",
    var.fetch_pr ? "export GITHUB_INVENTORY_PR=True" : "",
    var.fetch_issues ? "export GITHUB_INVENTORY_ISSUES=True" : "",
    "poetry run python -m github_inventory --org ${var.scanned_org}",
    "aws s3 cp ${var.ec2_workdir}/github_inventory-${var.project_version}/inventory-${var.scanned_org}.json s3://${data.aws_s3_bucket.resources_and_results.id}/outbound/json/inventory-${var.scanned_org}.json",
    "TOKEN=$(curl -X PUT \"http://169.254.169.254/latest/api/token\" -H \"X-aws-ec2-metadata-token-ttl-seconds: 21600\")",
    "export INSTANCE_ID=$(curl -H \"X-aws-ec2-metadata-token: $TOKEN\" -s http://169.254.169.254/latest/meta-data/instance-id)",
    var.terminate_instance_after_completion ? "aws ec2 terminate-instances --instance-ids $INSTANCE_ID" : ""
  ])


  tags = merge(var.tags, { Name = "${var.project_name}-ec2-${var.scanned_org}" })

  depends_on = [
    data.local_file.dist,
    null_resource.poetry_build,
    aws_s3_object.poetry_dist,
    aws_iam_policy.permissions_for_ec2_instance,
    aws_iam_role_policy_attachment.PermissionsForEC2InstancePolicyAttachment,
  ]
}
