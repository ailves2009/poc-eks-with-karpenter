# /modules/karpenter/main.tf
#
# Karpenter setup, three layers:
#   1. AWS-side IAM/SQS/EventBridge from terraform-aws-modules/eks/aws//modules/karpenter
#   2. Helm release of the Karpenter chart from the public ECR registry
#   3. Default EC2NodeClass + NodePool kubernetes manifests
#
# Workloads on the bootstrap managed node group are unaffected — Karpenter
# only manages nodes it itself launches.

# ---------------------------------------------------------------------------
# 1. IAM, SQS, EventBridge
# ---------------------------------------------------------------------------
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.30"

  cluster_name = var.cluster_name

  # IRSA for the Karpenter controller pod
  enable_irsa                     = true
  irsa_oidc_provider_arn          = var.oidc_provider_arn
  irsa_namespace_service_accounts = ["kube-system:karpenter"]

  iam_role_permissions_boundary_arn  = var.permissions_boundary_arn
  node_iam_role_permissions_boundary = var.permissions_boundary_arn

  # Attach the standard worker-node managed policies (CNI, ECR, SSM)
  node_iam_role_attach_cni_policy = true

  tags = var.tags
}

# ---------------------------------------------------------------------------
# 2. Helm release
# ---------------------------------------------------------------------------

provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
    }
  }
}

provider "kubectl" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
  }
}

resource "helm_release" "karpenter" {
  namespace = "kube-system"
  name      = "karpenter"
  # Vendored chart — avoids the helm provider v3 bug with OCI registry
  # token expiry on plan/update. To bump the chart version: pull a new
  # .tgz into modules/karpenter/charts/, update var.karpenter_chart_version,
  # commit. Image pulls (public.ecr.aws/karpenter/controller) at runtime
  # still work anonymously without ECR Public auth.
  chart = "${path.module}/charts/karpenter-${var.karpenter_chart_version}.tgz"
  wait  = true

  values = [yamlencode({
    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = module.karpenter.iam_role_arn
      }
    }
    settings = {
      clusterName       = var.cluster_name
      clusterEndpoint   = var.cluster_endpoint
      interruptionQueue = module.karpenter.queue_name
    }
  })]
}

# ---------------------------------------------------------------------------
# 3. Default EC2NodeClass + NodePool
# ---------------------------------------------------------------------------

resource "kubectl_manifest" "default_ec2_node_class" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiSelectorTerms = [{ alias = "al2023@latest" }]
      role             = module.karpenter.node_iam_role_name

      subnetSelectorTerms = [{
        tags = { "karpenter.sh/discovery" = var.cluster_name }
      }]

      securityGroupSelectorTerms = [{
        tags = { "karpenter.sh/discovery" = var.cluster_name }
      }]

      tags = merge(var.tags, {
        "karpenter.sh/discovery" = var.cluster_name
      })
    }
  })

  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "default_node_pool" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "default"
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "default"
          }
          requirements = [
            { key = "kubernetes.io/arch", operator = "In", values = ["amd64", "arm64"] },
            { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot", "on-demand"] },
            { key = "karpenter.k8s.aws/instance-category", operator = "In", values = var.instance_categories },
            { key = "karpenter.k8s.aws/instance-cpu", operator = "In", values = var.instance_cpu_choices },
            { key = "karpenter.k8s.aws/instance-generation", operator = "Gt", values = ["2"] },
          ]
        }
      }
      limits = {
        cpu = var.node_pool_cpu_limit
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "30s"
      }
    }
  })

  depends_on = [
    helm_release.karpenter,
    kubectl_manifest.default_ec2_node_class,
  ]
}
