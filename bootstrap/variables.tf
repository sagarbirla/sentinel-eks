variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "backend_bucket_name" {
  description = "S3 bucket name for Terraform backend"
  type        = string
  default     = "rapyd-poc-sagar-terraform-state"
}