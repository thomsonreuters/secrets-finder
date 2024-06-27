data "aws_security_groups" "custom_security_groups" {
  count = length(var.aws_default_security_groups_filters) > 0 ? 1 : 0

  filter {
    name   = "group-name"
    values = var.aws_default_security_groups_filters
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# Data source for the default security group, always fetched but conditionally used
data "aws_security_group" "default" {
  count = length(var.aws_default_security_groups_filters) > 0 ? 0 : 1

  vpc_id = data.aws_vpc.selected.id
  name   = "default"
}
