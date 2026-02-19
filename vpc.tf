# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Gateway VPC
module "vpc_gateway" {
  source = "./modules/vpc"

  vpc_name             = "gateway"
  vpc_cidr             = var.gateway_vpc_cidr
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets      = var.gateway_private_subnets
  public_subnets       = var.gateway_public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Tier = "Gateway"
  }
}

# Backend VPC
module "vpc_backend" {
  source = "./modules/vpc"

  vpc_name             = "backend"
  vpc_cidr             = var.backend_vpc_cidr
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets      = var.backend_private_subnets
  public_subnets       = var.backend_public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Tier = "Backend"
  }
}

# VPC Peering between Gateway and Backend
module "vpc_peering" {
  source = "./modules/networking"

  requester_vpc_id = module.vpc_gateway.vpc_id
  accepter_vpc_id  = module.vpc_backend.vpc_id

  requester_vpc_cidr = var.gateway_vpc_cidr
  accepter_vpc_cidr  = var.backend_vpc_cidr

  #requester_route_table_ids = module.vpc_gateway.private_route_table_ids
  requester_route_table_ids = concat(module.vpc_gateway.private_route_table_ids, module.vpc_gateway.public_route_table_ids)
  accepter_route_table_ids  = concat(module.vpc_backend.private_route_table_ids, module.vpc_backend.public_route_table_ids)

  tags = {
    Name = "gateway-to-backend-peering"
  }
}
