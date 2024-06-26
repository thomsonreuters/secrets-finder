locals {
  environment = replace(lower(var.environment_type), " ", "-")
  tags        = merge(try(var.tags, {}), { environment = local.environment })
}
