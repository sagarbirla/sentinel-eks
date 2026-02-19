# IAM Module Variables

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "assume_role_policy" {
  description = "The assume role policy document in JSON format"
  type        = string
}

variable "custom_policy_document" {
  description = "The policy document for custom IAM policy (JSON format). If null, no custom policy will be created"
  type        = string
  default     = null
}

variable "policy_name" {
  description = "Name of the custom IAM policy. If null, will default to {role_name}-policy"
  type        = string
  default     = null
}

variable "policy_description" {
  description = "Description of the custom IAM policy"
  type        = string
  default     = ""
}

variable "managed_policy_arns" {
  description = "List of managed IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}
