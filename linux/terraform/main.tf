terraform {}

provider "aws" {
  region = local.region
}

locals {
  db_ip  = "10.0.1.10"
  region = var.aws_region
  name   = "${var.event}-osc-workshop-linux"
  tags = {
    event               = var.event
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = "10.0.0.0/16"

  azs            = ["${local.region}a"]
  public_subnets = ["10.0.1.0/24"]

  enable_nat_gateway = false

  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = local.name
  description = "Security group for local IP ssh"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["${chomp(data.http.my_ip.body)}/32"]
  ingress_rules       = ["ssh-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

module "db" {
  count   = 0
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  ami        = data.aws_ami.latest.id
  subnet_id  = module.vpc.public_subnets[0]
  private_ip = local.db_ip
}

module "team_server" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  for_each = toset(["1", "2"])
  name     = "${local.name}-team${each.key}"

  ami                    = data.aws_ami.latest.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [module.security_group.security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = local.tags
}

resource "aws_key_pair" "main" {
  key_name   = local.name
  public_key = file(pathexpand("~/.ssh/id_rsa.pub"))
}
