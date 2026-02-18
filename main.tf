terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Backend configuration for state management
  # Uncomment and configure for production use
  # backend "s3" {
  #   bucket         = "rapyd-sentinel-terraform-state"
  #   key            = "infra/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "RapydSentinel"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Platform-Team"
    }
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Gateway VPC
module "vpc_gateway" {
  source = "./modules/vpc"

  vpc_name            = "vpc-gateway"
  vpc_cidr            = var.gateway_vpc_cidr
  availability_zones  = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets     = var.gateway_private_subnets
  public_subnets      = var.gateway_public_subnets
  enable_nat_gateway  = true
  single_nat_gateway  = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Tier = "Gateway"
  }
}

# Backend VPC
module "vpc_backend" {
  source = "./modules/vpc"

  vpc_name            = "vpc-backend"
  vpc_cidr            = var.backend_vpc_cidr
  availability_zones  = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets     = var.backend_private_subnets
  public_subnets      = var.backend_public_subnets
  enable_nat_gateway  = true
  single_nat_gateway  = var.single_nat_gateway
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

  requester_route_table_ids = module.vpc_gateway.private_route_table_ids
  accepter_route_table_ids  = module.vpc_backend.private_route_table_ids

  tags = {
    Name = "gateway-to-backend-peering"
  }
}

# EKS Gateway Cluster
module "eks_gateway" {
  source = "./modules/eks"

  cluster_name    = "eks-gateway"
  cluster_version = var.eks_version
  vpc_id          = module.vpc_gateway.vpc_id
  subnet_ids      = module.vpc_gateway.private_subnet_ids

  node_group_name     = "gateway-nodes"
  node_instance_types = var.gateway_node_instance_types
  node_desired_size   = var.gateway_node_desired_size
  node_min_size       = var.gateway_node_min_size
  node_max_size       = var.gateway_node_max_size

  # Security group rules
  additional_security_group_rules = {
    ingress_from_alb = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP from ALB"
    }
    egress_to_backend_vpc = {
      type        = "egress"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = [var.backend_vpc_cidr]
      description = "Allow traffic to backend VPC"
    }
  }

  tags = {
    Tier = "Gateway"
  }
}

# EKS Backend Cluster
module "eks_backend" {
  source = "./modules/eks"

  cluster_name    = "eks-backend"
  cluster_version = var.eks_version
  vpc_id          = module.vpc_backend.vpc_id
  subnet_ids      = module.vpc_backend.private_subnet_ids

  node_group_name     = "backend-nodes"
  node_instance_types = var.backend_node_instance_types
  node_desired_size   = var.backend_node_desired_size
  node_min_size       = var.backend_node_min_size
  node_max_size       = var.backend_node_max_size

  # Security group rules
  additional_security_group_rules = {
    ingress_from_gateway_vpc = {
      type        = "ingress"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = [var.gateway_vpc_cidr]
      description = "Allow traffic from gateway VPC only"
    }
  }

  tags = {
    Tier = "Backend"
  }
}
