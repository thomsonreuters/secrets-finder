locals {
  environment = replace(lower(var.environment_type), " ", "-")
  tags        = var.tags
}
