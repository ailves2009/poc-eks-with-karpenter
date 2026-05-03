# /non-prod/poc/us-east-1/workload/eks/terragrunt.hcl

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  tags         = local.account_vars.locals.tags
  cluster_name = local.region_vars.locals.cluster_name
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../modules/eks"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    private_subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
  }
}

dependency "iam_state" {
  config_path = "../../bootstrap/iam-state"

  mock_outputs = {
    permissions_boundary_arn = "arn:aws:iam::000000000000:policy/mock-boundary"
  }
}

inputs = {
  cluster_name    = local.cluster_name
  cluster_version = "1.32"

  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids

  permissions_boundary_arn = dependency.iam_state.outputs.permissions_boundary_arn

  # 2 nodes across 2 AZs so the Karpenter chart's default 2 replicas can
  # satisfy its zone topology-spread constraint.
  bootstrap_node_min_size     = 2
  bootstrap_node_desired_size = 2
  bootstrap_node_max_size     = 3

  tags = local.tags
}
