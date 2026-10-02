module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.name}-vpc"
  cidr = var.vpc_cidr

  azs            = local.azs
  public_subnets = local.public_subnets

  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = false

  # A single public subnet is sufficient for an all-in-one demo host.
  enable_nat_gateway = false
}
