terraform {
  required_version = ">= 1.12.0"

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

  backend "s3" {
    bucket       = "rapyd-poc-sagar-terraform-state"
    key          = "infra/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  # default_tags {
  #   tags = {
  #     Project     = "RapydSentinel"
  #     Environment = var.environment
  #     ManagedBy   = "Terraform"
  #     Owner       = "Platform-Team"
  #   }
  # }
}
