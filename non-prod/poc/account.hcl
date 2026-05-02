# filepath: non-prod/account.hcl

# Set account-wide variables. These are automatically pulled in to configure the remote state bucket in the root
# terragrunt.hcl configuration.
locals {
  aws_account_id          = "470201305353"
  account_name            = "poc"
  env                     = "plt"
  client                  = "poc"
  # Placeholder. POC does not own a delegated DNS zone in this account
  # (corp domain echotwin.xyz isn't delegated; ailves2009.com is in another
  # account; cross-account delegation is in TODO). Used as suffix for the
  # nginx Ingress hostname — tested via `curl --resolve`.
  domain_name             = "poc-eks-karpenter.domain.xyz"
  cicd_role_name          = "cicd-deployment-role"
  s3_terraform_state      = "nyd-plt-tf-state"
  managed_role_names = [
    "eks-irsa-app-role",
    "aws-load-balancer-controller-role",
    "karpenter-controller-role",
    "karpenter-node-role",
  ]
  tags                = {
    Env                 = "plt"
    Client              = "poc"
    Managed             = "terraform"
    Project             = "poc-aws-eks-karpenter"
    Github              = ".."
  }
}