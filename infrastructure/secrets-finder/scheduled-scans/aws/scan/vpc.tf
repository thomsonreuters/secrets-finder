data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }

  filter {
    name   = "available-ip-address-count"
    values = range(1, 200)
  }
}
