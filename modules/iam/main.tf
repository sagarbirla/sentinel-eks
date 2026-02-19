terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
# IAM Module - Manages IAM roles, policies, and attachments

# Generate random suffix for role name
resource "random_string" "role_suffix" {
  length  = 8
  special = false
  upper   = false
}

# IAM Role
resource "aws_iam_role" "this" {
  name               = "${var.role_name}-${random_string.role_suffix.result}"
  assume_role_policy = var.assume_role_policy
}

# Custom IAM Policy
resource "aws_iam_policy" "this" {
  count       = var.custom_policy_document != null ? 1 : 0
  name        = var.policy_name != null ? var.policy_name : "${var.role_name}-policy"
  description = var.policy_description
  policy      = var.custom_policy_document
}

# Attach custom policy to role
resource "aws_iam_role_policy_attachment" "custom_policy" {
  count      = var.custom_policy_document != null ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[0].arn
}

# Attach managed policies to role
resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}
