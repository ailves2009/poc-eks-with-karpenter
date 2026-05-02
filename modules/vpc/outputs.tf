# /modules/vpc/outputs.tf

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC primary CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs (one per AZ)"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnet IDs (one per AZ) — where EKS workers run"
  value       = module.vpc.private_subnets
}

output "azs" {
  description = "Availability zones used"
  value       = module.vpc.azs
}

output "nat_public_ips" {
  description = "Public IPs of NAT Gateways (for whitelisting outbound traffic from EKS workers)"
  value       = module.vpc.nat_public_ips
}
