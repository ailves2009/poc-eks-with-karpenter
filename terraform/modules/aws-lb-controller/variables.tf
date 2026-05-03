# /modules/aws-lb-controller/variables.tf

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS API server endpoint"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 EKS CA"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for the cluster (for IRSA)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster runs (passed to the chart for ALB targeting)"
  type        = string
}

variable "permissions_boundary_arn" {
  description = "Permissions boundary attached to the IRSA role"
  type        = string
}

variable "chart_version" {
  description = "aws-load-balancer-controller Helm chart version"
  type        = string
  default     = "1.10.0"
}

variable "replica_count" {
  description = "Number of controller replicas (>= 2 for HA across AZs)"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags applied to all AWS resources"
  type        = map(string)
  default     = {}
}
