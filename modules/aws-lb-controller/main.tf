# /modules/aws-lb-controller/main.tf
#
# AWS Load Balancer Controller — turns Kubernetes Ingress / Service:LoadBalancer
# resources into ALBs / NLBs. Two pieces:
#   1. IRSA role with the well-known ALB controller policy.
#   2. Helm chart from the official EKS charts repo.
#
# Subnet discovery uses the tags we already set in modules/vpc:
#   public:  kubernetes.io/role/elb=1            → public-facing ALB
#   private: kubernetes.io/role/internal-elb=1   → internal ALB / NLB

# ---------------------------------------------------------------------------
# 1. IRSA
# ---------------------------------------------------------------------------
module "irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name                              = "aws-load-balancer-controller-${var.cluster_name}"
  attach_load_balancer_controller_policy = true
  role_permissions_boundary_arn          = var.permissions_boundary_arn

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# 2. Helm
# ---------------------------------------------------------------------------
provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks", "get-token",
        "--cluster-name", var.cluster_name,
        "--region", var.region,
      ]
    }
  }
}

resource "helm_release" "alb" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version

  atomic  = true
  wait    = true
  timeout = 300

  values = [yamlencode({
    clusterName = var.cluster_name
    region      = var.region
    vpcId       = var.vpc_id

    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
      annotations = {
        "eks.amazonaws.com/role-arn" = module.irsa.iam_role_arn
      }
    }

    # System component — pin to bootstrap NG, survives Karpenter consolidation.
    nodeSelector = {
      "node-role" = "bootstrap"
    }

    replicaCount = var.replica_count

    # Spread replicas across zones for HA (DoNotSchedule is safe here because
    # the bootstrap NG has 2 nodes in 2 AZs).
    topologySpreadConstraints = [{
      maxSkew           = 1
      topologyKey       = "topology.kubernetes.io/zone"
      whenUnsatisfiable = "DoNotSchedule"
      labelSelector = {
        matchLabels = {
          "app.kubernetes.io/name"     = "aws-load-balancer-controller"
          "app.kubernetes.io/instance" = "aws-load-balancer-controller"
        }
      }
    }]
  })]
}
