# IAM Module Outputs

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "ID of the IAM role"
  value       = aws_iam_role.this.id
}

output "policy_arn" {
  description = "ARN of the custom IAM policy"
  value       = var.custom_policy_document != null ? aws_iam_policy.this[0].arn : null
}

output "policy_name" {
  description = "Name of the custom IAM policy"
  value       = var.custom_policy_document != null ? aws_iam_policy.this[0].name : null
}

output "managed_policy_arns" {
  description = "List of managed policy ARNs attached to the role"
  value       = var.managed_policy_arns
}
