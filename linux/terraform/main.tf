terraform {}

provider "aws" {
  region = local.region
}

locals {
  db_ip    = "10.0.1.10"
  region   = var.aws_region
  name     = "${var.event}-osc-workshop-linux"
  my_cidr  = "${chomp(data.http.my_ip.body)}/32"
  tags = {
    event               = var.event
    does_ryan_check_prs = true
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

  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Score server dashboard"
      cidr_blocks = local.my_cidr
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "Score DB for team servers"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "Score DB for deployer"
      cidr_blocks = local.my_cidr
    }
  ]

  tags = local.tags
}

module "db" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"

  name = "${local.name}-db"

  ami                         = data.aws_ami.latest.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [module.security_group.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  tags = local.tags
}

module "team_servers" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"

  count = var.num_teams

  name = "${local.name}-team-${count.index + 1}"

  ami                         = data.aws_ami.latest.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [module.security_group.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  tags = local.tags
}

resource "aws_key_pair" "main" {
  key_name   = local.name
  public_key = file(pathexpand(var.ssh_local_key_path))
}
