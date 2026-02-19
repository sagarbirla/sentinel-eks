# # GitHub Actions OIDC Configuration and IAM Role/Policy

# # IAM Role for GitHub Actions
# module "github_actions_iam" {
#   source = "./modules/iam"

#   role_name          = "sentinel-github-actions"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
#             "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:ref:refs/heads/${var.github_branch}"
#           }
#         }
#       }
#     ]
#   })

#   custom_policy_document = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "TerraformStateManagement"
#         Effect = "Allow"
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject",
#           "s3:ListBucket"
#         ]
#         Resource = [
#           "arn:aws:s3:::rapyd-sentinel-terraform-state",
#           "arn:aws:s3:::rapyd-sentinel-terraform-state/*"
#         ]
#       },
#       {
#         Sid    = "TerraformStateLocking"
#         Effect = "Allow"
#         Action = [
#           "dynamodb:DescribeTable",
#           "dynamodb:GetItem",
#           "dynamodb:PutItem",
#           "dynamodb:DeleteItem"
#         ]
#         Resource = "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/terraform-state-lock"
#       },
#       {
#         Sid    = "IAMManagement"
#         Effect = "Allow"
#         Action = [
#           "iam:CreateRole",
#           "iam:UpdateRole",
#           "iam:DeleteRole",
#           "iam:GetRole",
#           "iam:ListRoles",
#           "iam:CreatePolicy",
#           "iam:GetPolicy",
#           "iam:DeletePolicy",
#           "iam:ListPolicies",
#           "iam:AttachRolePolicy",
#           "iam:DetachRolePolicy",
#           "iam:ListRolePolicies",
#           "iam:ListAttachedRolePolicies",
#           "iam:TagRole"
#         ]
#         Resource = "*"
#       },
#       {
#         Sid    = "VPCManagement"
#         Effect = "Allow"
#         Action = [
#           "ec2:CreateVpc",
#           "ec2:DeleteVpc",
#           "ec2:DescribeVpcs",
#           "ec2:ModifyVpcAttribute",
#           "ec2:CreateSubnet",
#           "ec2:DeleteSubnet",
#           "ec2:DescribeSubnets",
#           "ec2:CreateInternetGateway",
#           "ec2:DeleteInternetGateway",
#           "ec2:DescribeInternetGateways",
#           "ec2:AttachInternetGateway",
#           "ec2:DetachInternetGateway",
#           "ec2:CreateNatGateway",
#           "ec2:DeleteNatGateway",
#           "ec2:DescribeNatGateways",
#           "ec2:AllocateAddress",
#           "ec2:ReleaseAddress",
#           "ec2:DescribeAddresses",
#           "ec2:CreateRouteTable",
#           "ec2:DeleteRouteTable",
#           "ec2:DescribeRouteTables",
#           "ec2:CreateRoute",
#           "ec2:DeleteRoute",
#           "ec2:AssociateRouteTable",
#           "ec2:DisassociateRouteTable",
#           "ec2:CreateSecurityGroup",
#           "ec2:DeleteSecurityGroup",
#           "ec2:DescribeSecurityGroups",
#           "ec2:AuthorizeSecurityGroupIngress",
#           "ec2:RevokeSecurityGroupIngress",
#           "ec2:AuthorizeSecurityGroupEgress",
#           "ec2:RevokeSecurityGroupEgress",
#           "ec2:CreateVpcPeeringConnection",
#           "ec2:DeleteVpcPeeringConnection",
#           "ec2:DescribeVpcPeeringConnections",
#           "ec2:AcceptVpcPeeringConnection",
#           "ec2:RejectVpcPeeringConnection"
#         ]
#         Resource = "*"
#       },
#       {
#         Sid    = "EKSManagement"
#         Effect = "Allow"
#         Action = [
#           "eks:CreateCluster",
#           "eks:DeleteCluster",
#           "eks:DescribeCluster",
#           "eks:ListClusters",
#           "eks:UpdateClusterVersion",
#           "eks:CreateNodegroup",
#           "eks:DeleteNodegroup",
#           "eks:DescribeNodegroup",
#           "eks:ListNodegroups",
#           "eks:UpdateNodegroupVersion",
#           "eks:UpdateNodegroupConfig"
#         ]
#         Resource = "*"
#       },
#       {
#         Sid    = "EC2InstanceManagement"
#         Effect = "Allow"
#         Action = [
#           "ec2:DescribeInstances",
#           "ec2:DescribeLaunchTemplates",
#           "autoscaling:DescribeAutoScalingGroups",
#           "autoscaling:DescribeScalingActivities"
#         ]
#         Resource = "*"
#       },
#       {
#         Sid    = "KubernetesDeployment"
#         Effect = "Allow"
#         Action = [
#           "eks:AccessKubernetesApi"
#         ]
#         Resource = "*"
#       }
#     ]
#   })

#   managed_policy_arns = []
# }

# # Data source to get current AWS account ID
# data "aws_caller_identity" "current" {}

# # Outputs for GitHub Actions configuration
# output "github_actions_role_arn" {
#   description = "ARN of the IAM role for GitHub Actions"
#   value       = module.github_actions_iam.role_arn
# }

# output "github_actions_role_name" {
#   description = "Name of the IAM role for GitHub Actions"
#   value       = module.github_actions_iam.role_name
# }
