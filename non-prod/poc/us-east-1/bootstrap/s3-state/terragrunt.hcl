# /envs/main/poc/bootstrap/s3-state/terragrunt.hcl

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  region       = local.region_vars.locals.aws_region
  tags         = local.account_vars.locals.tags
}

terraform {
  source = "../../../../../modules/s3-state"
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "local" {}
}
EOF
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region  = "${local.region}"
  default_tags {
    tags = {
      Env         = "${local.tags["Env"]}"
      Client      = "${local.tags["Client"]}"
      Managed     = "${local.tags["Managed"]}"
      Project     = "${local.tags["Project"]}"
      Github      = "${local.tags["Github"]}"
    }
  }  
}
EOF
}

dependency "bootstrap_iam_state" {
  config_path = "../iam-state"

  mock_outputs = {
    deploy_role_arn  = "mock-cicd-arn"
  }
}

inputs = {
  bucket_name               = local.account_vars.locals.s3_terraform_state
  versioning                = false
  deploy_role_arn           = dependency.bootstrap_iam_state.outputs.deploy_role_arn # needed for assign policy for s3 bucket
}