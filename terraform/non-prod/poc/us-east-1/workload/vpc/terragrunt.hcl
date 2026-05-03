# /non-prod/poc/us-east-1/workload/vpc/terragrunt.hcl

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
  source = "../../../../../modules/vpc"
}

inputs = {
  name = "nyd-plt-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets = ["10.0.16.0/20", "10.0.32.0/20"]

  single_nat_gateway = true

  cluster_name = local.cluster_name
  tags         = local.tags
}
