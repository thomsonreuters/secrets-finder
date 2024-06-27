output "ec2_role_arn" {
  value = aws_iam_role.ec2_role.arn
}

output "ec2_instance_id" {
  value = aws_instance.ec2_inventory.id
}

output "ec2_instance_arn" {
  value = aws_instance.ec2_inventory.arn
}
