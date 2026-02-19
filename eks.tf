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

# # EKS Access Entry for GitHub Actions - Gateway Cluster
# resource "aws_eks_access_entry" "github_gateway" {
#   cluster_name      = module.eks_gateway.cluster_name
#   principal_arn     = module.github_actions_iam.role_arn
#   kubernetes_groups = ["github-actions"]
#   type              = "STANDARD"
# }

# # EKS Access Policy Association for GitHub Actions - Gateway Cluster
# resource "aws_eks_access_policy_association" "github_gateway_admin" {
#   cluster_name       = module.eks_gateway.cluster_name
#   policy_arn         = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
#   principal_arn      = module.github_actions_iam.role_arn
#   access_scope {
#     type = "cluster"
#   }
# }

# # EKS Access Entry for GitHub Actions - Backend Cluster
# resource "aws_eks_access_entry" "github_backend" {
#   cluster_name      = module.eks_backend.cluster_name
#   principal_arn     = module.github_actions_iam.role_arn
#   kubernetes_groups = ["github-actions"]
#   type              = "STANDARD"
# }

# # EKS Access Policy Association for GitHub Actions - Backend Cluster
# resource "aws_eks_access_policy_association" "github_backend_admin" {
#   cluster_name       = module.eks_backend.cluster_name
#   policy_arn         = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
#   principal_arn      = module.github_actions_iam.role_arn
#   access_scope {
#     type = "cluster"
#   }
# }

# EKS Access Policy Association for GitHub Actions - Backend Cluster (Edit)
# resource "aws_eks_access_policy_association" "github_backend_edit" {
#   cluster_name       = module.eks_backend.cluster_name
#   policy_arn         = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
#   principal_arn      = module.github_actions_iam.role_arn
#   access_scope {
#     type = "cluster"
#   }
# }

# EKS Access Policy Association for GitHub Actions - Gateway Cluster (Edit)
# resource "aws_eks_access_policy_association" "github_gateway_edit" {
#   cluster_name       = module.eks_gateway.cluster_name
#   policy_arn         = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
#   principal_arn      = module.github_actions_iam.role_arn
#   access_scope {
#     type = "cluster"
#   }
# }