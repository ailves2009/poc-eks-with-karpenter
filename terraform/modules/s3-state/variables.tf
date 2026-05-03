# /modules/s3-state/inputs.tf

variable "bucket_name" {
  description = "S3 bucket name for storing Terraform state"
  type        = string
}

variable "deploy_role_arn" {
  description = "The ARN of the CICD deployment role"
  type        = string
}

variable "versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = false
}
