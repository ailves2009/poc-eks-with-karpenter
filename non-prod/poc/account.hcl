# filepath: non-prod/account.hcl

# Set account-wide variables. These are automatically pulled in to configure the remote state bucket in the root
# terragrunt.hcl configuration.
locals {
  # Replace with your AWS account ID before first apply.
  aws_account_id          = "111122223333"
  account_name            = "poc"
  env                     = "plt"
  client                  = "poc"
  # Placeholder. The POC does not own a Route53 zone in this account, so
  # this value is only used as a Host-header suffix for the nginx Ingress
  # rule (tested via `curl --resolve`). Replace with a domain you control
  # if you want real DNS resolution + ACM. See README → "Before you start".
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