data "aws_s3_bucket" "resources_and_results" {
  bucket = var.s3_bucket_name
}

resource "null_resource" "poetry_build" {
  provisioner "local-exec" {
    command     = "poetry build -f sdist"
    working_dir = "${var.inventory_project_dir}/"
  }

  triggers = {
    always_run = timestamp()
  }
}

data "local_file" "dist" {
  filename   = "${var.inventory_project_dir}/dist/github_inventory-${var.project_version}.tar.gz"
  depends_on = [null_resource.poetry_build]
}

resource "aws_s3_object" "poetry_dist" {
  bucket      = data.aws_s3_bucket.resources_and_results.id
  key         = "inventory/scripts/poetry_dist/github_inventory-${var.project_version}.tar.gz"
  source      = "${var.inventory_project_dir}/dist/github_inventory-${var.project_version}.tar.gz"
  source_hash = data.local_file.dist.content_sha256
  depends_on  = [data.local_file.dist]
}
