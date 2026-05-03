# /modules/helm-release/main.tf
#
# Generic Helm release wrapper. Configures the helm provider to talk to
# an EKS cluster via `aws eks get-token`, then installs a single chart.
# Reuse for any standalone Helm app (nginx, prometheus, grafana, ...).

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

resource "helm_release" "this" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = var.create_namespace

  repository = var.repository
  chart      = var.chart
  version    = var.chart_version

  atomic  = var.atomic
  wait    = var.wait
  timeout = var.timeout

  # `values` map first, then any extra raw YAML overrides on top.
  values = concat(
    [yamlencode(var.values)],
    var.values_yaml,
  )
}
