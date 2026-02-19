# IAM Resources
# Add IAM-specific resources here (if needed at the root level)

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