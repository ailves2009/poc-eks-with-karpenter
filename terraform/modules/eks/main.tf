# /modules/eks/main.tf
#
# Thin wrapper around terraform-aws-modules/eks/aws.
# Local conventions baked in:
#   - permissions boundary on every IAM role
#   - sensible cluster addons (CNI, coredns, kube-proxy, EBS CSI, Pod Identity)
#   - bootstrap managed node group on Graviton (Karpenter must run somewhere)
#   - api/audit/authenticator log streams
#   - envelope encryption for secrets via a module-managed KMS key

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.30"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.private_subnet_ids

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Grants the IAM principal that runs `terraform apply` (cicd-deployment-role)
  # cluster-admin via an EKS Access Entry. Lets future terraform runs (helm,
  # kubernetes_manifest) reach the cluster without manual aws-auth fiddling.
  enable_cluster_creator_admin_permissions = true

  iam_role_permissions_boundary = var.permissions_boundary_arn

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = { before_compute = true } # install before nodes join
    eks-pod-identity-agent = {}
    # aws-ebs-csi-driver: requires an IRSA role / Pod Identity Association
    # to authenticate the controller. Add back together with that wiring when
    # PersistentVolumes become a requirement.
  }

  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  cluster_encryption_config = {
    resources = ["secrets"]
  }

  # Tag the node security group so Karpenter EC2NodeClass can find it via
  # `securityGroupSelectorTerms.tags."karpenter.sh/discovery"`.
  node_security_group_tags = merge(var.tags, {
    "karpenter.sh/discovery" = var.cluster_name
  })

  # Minimal node group — enough to run kube-system pods and Karpenter itself.
  # Karpenter takes over for application workloads.
  eks_managed_node_groups = {
    bootstrap = {
      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = var.bootstrap_node_instance_types # Graviton2-based, 2 vCPU and 4 GB RAM. Adjust based on your workload needs.

      min_size     = var.bootstrap_node_min_size
      max_size     = var.bootstrap_node_max_size
      desired_size = var.bootstrap_node_desired_size

      iam_role_permissions_boundary = var.permissions_boundary_arn

      labels = {
        "node-role" = "bootstrap"
      }
    }
  }

  tags = var.tags
}
