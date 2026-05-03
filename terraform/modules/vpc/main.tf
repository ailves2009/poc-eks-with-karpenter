# /modules/vpc/main.tf
#
# Thin wrapper around terraform-aws-modules/vpc/aws.
# The upstream module handles VPC, subnets, IGW, NAT, route tables,
# default-SG/NACL hardening. This wrapper just bakes in project conventions:
#   - single NAT for cost (overridable)
#   - EKS / Karpenter subnet discovery tags
#   - DNS hostnames on (required for EKS)

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13"

  name = var.name
  cidr = var.cidr

  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Subnet tags for Kubernetes / EKS / Karpenter / ALB Controller discovery.
  # https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html
  # https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/deploy/subnet_discovery/
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "karpenter.sh/discovery"                    = var.cluster_name
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  tags = var.tags
}
