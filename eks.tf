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