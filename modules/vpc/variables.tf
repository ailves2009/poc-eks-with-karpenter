# /modules/vpc/variables.tf

variable "name" {
  description = "VPC name. Becomes the Name tag and prefix for subnets/route-tables."
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across. Length must match public_subnets/private_subnets."
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDRs for public subnets (one per AZ). Used by ALBs / NAT Gateway."
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDRs for private subnets (one per AZ). Used by EKS worker nodes."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use one NAT Gateway shared across AZs (POC, ~$32/mo) instead of one per AZ (HA, ~$96/mo)."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name — added as karpenter.sh/discovery=<cluster_name> tag on private subnets so Karpenter can find them."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
