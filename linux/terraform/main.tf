terraform {}

provider "aws" {
  region = local.region
}

locals {
  db_ip  = "10.0.1.10"
  region = var.aws_region

  tags = {

  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "osc-workshop-linux"
  cidr = "10.0.0.0/16"

  azs            = ["${local.region}a"]
  public_subnets = ["10.0.1.0/24"]

  enable_nat_gateway = false

  tags = local.tags
}

module "db" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  subnet_id  = module.vpc.public_subnets[0].subnet_id
  private_ip = local.db_ip
}

module "team_server" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  for_each = toset(["1", "2"])

  subnet_id = module.vpc.public_subnets[0].subnet_id
}
