data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }
}

data "aws_subnet" "selected" {
  id = element(sort(data.aws_subnets.default.ids), 0)
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.selected.id
  name   = "default"
}
