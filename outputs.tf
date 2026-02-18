output "gateway_vpc_id" {
  description = "ID of the gateway VPC"
  value       = module.vpc_gateway.vpc_id
}

output "gateway_vpc_cidr" {
  description = "CIDR block of the gateway VPC"
  value       = module.vpc_gateway.vpc_cidr
}

output "backend_vpc_id" {
  description = "ID of the backend VPC"
  value       = module.vpc_backend.vpc_id
}

output "backend_vpc_cidr" {
  description = "CIDR block of the backend VPC"
  value       = module.vpc_backend.vpc_cidr
}

output "vpc_peering_connection_id" {
  description = "ID of the VPC peering connection"
  value       = module.vpc_peering.peering_connection_id
}

output "eks_gateway_cluster_name" {
  description = "Name of the gateway EKS cluster"
  value       = module.eks_gateway.cluster_name
}

output "eks_gateway_cluster_endpoint" {
  description = "Endpoint of the gateway EKS cluster"
  value       = module.eks_gateway.cluster_endpoint
}

output "eks_gateway_cluster_security_group_id" {
  description = "Security group ID of the gateway EKS cluster"
  value       = module.eks_gateway.cluster_security_group_id
}

output "eks_backend_cluster_name" {
  description = "Name of the backend EKS cluster"
  value       = module.eks_backend.cluster_name
}

output "eks_backend_cluster_endpoint" {
  description = "Endpoint of the backend EKS cluster"
  value       = module.eks_backend.cluster_endpoint
}

output "eks_backend_cluster_security_group_id" {
  description = "Security group ID of the backend EKS cluster"
  value       = module.eks_backend.cluster_security_group_id
}

output "configure_kubectl_gateway" {
  description = "Command to configure kubectl for gateway cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks_gateway.cluster_name}"
}

output "configure_kubectl_backend" {
  description = "Command to configure kubectl for backend cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks_backend.cluster_name} --alias eks-backend"
}
