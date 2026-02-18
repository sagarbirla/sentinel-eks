variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "poc"
}

# VPC Configuration
variable "gateway_vpc_cidr" {
  description = "CIDR block for gateway VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "gateway_private_subnets" {
  description = "Private subnet CIDRs for gateway VPC"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "gateway_public_subnets" {
  description = "Public subnet CIDRs for gateway VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "backend_vpc_cidr" {
  description = "CIDR block for backend VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "backend_private_subnets" {
  description = "Private subnet CIDRs for backend VPC"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.11.0/24"]
}

variable "backend_public_subnets" {
  description = "Public subnet CIDRs for backend VPC (for NAT gateway)"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "single_nat_gateway" {
  description = "Use single NAT gateway for cost optimization"
  type        = bool
  default     = true
}

# EKS Configuration
variable "eks_version" {
  description = "Kubernetes version for EKS clusters"
  type        = string
  default     = "1.34"
}

# Gateway EKS Node Configuration
variable "gateway_node_instance_types" {
  description = "Instance types for gateway EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "gateway_node_desired_size" {
  description = "Desired number of gateway nodes"
  type        = number
  default     = 2
}

variable "gateway_node_min_size" {
  description = "Minimum number of gateway nodes"
  type        = number
  default     = 2
}

variable "gateway_node_max_size" {
  description = "Maximum number of gateway nodes"
  type        = number
  default     = 4
}

# Backend EKS Node Configuration
variable "backend_node_instance_types" {
  description = "Instance types for backend EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "backend_node_desired_size" {
  description = "Desired number of backend nodes"
  type        = number
  default     = 2
}

variable "backend_node_min_size" {
  description = "Minimum number of backend nodes"
  type        = number
  default     = 2
}

variable "backend_node_max_size" {
  description = "Maximum number of backend nodes"
  type        = number
  default     = 4
}
