data "aws_ami" "amazon_ami" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = ["${var.ami_image_filter}"]
  }
}
