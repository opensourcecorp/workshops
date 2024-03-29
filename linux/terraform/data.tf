data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

# https://wiki.debian.org/Cloud/AmazonEC2Image/Bullseye
data "aws_ami" "latest" {
  most_recent = true
  owners      = ["136693071363"] # Debian

  filter {
    name   = "name"
    values = ["debian-12-amd64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}
