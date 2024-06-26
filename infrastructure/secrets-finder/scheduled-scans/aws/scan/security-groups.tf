data "aws_security_group" "existing_security_groups" {
  for_each = { for sg in var.existing_security_groups : sg => sg }
  filter {
    name   = "group-name"
    values = [each.value]
  }
  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_security_group" "new_security_groups" {
  for_each    = { for sg in var.new_security_groups : sg.name => sg }
  name        = each.value.name
  description = each.value.description
  vpc_id      = data.aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = each.value["ingress"]
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      description      = ingress.value.description
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      security_groups  = ingress.value.security_groups
      prefix_list_ids  = ingress.value.prefix_list_ids
    }
  }

  dynamic "egress" {
    for_each = each.value["egress"]
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      description      = egress.value.description
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      security_groups  = egress.value.security_groups
      prefix_list_ids  = egress.value.prefix_list_ids
    }
  }
}
