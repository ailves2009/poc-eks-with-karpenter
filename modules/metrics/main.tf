# modules/metrics/main.tf

provider "helm" {
  kubernetes = {
    host                   = var.kube_host
    cluster_ca_certificate = var.kube_ca
    token                  = var.kube_token
  }
}

resource "helm_release" "metrics" {
  name       = "metrics"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = var.metrics_server_helm_version
  namespace  = var.metrics_server_namespace
  wait       = true

  # Use list-style `set` argument expected by helm provider (array of maps).
  set = [
    {
      name  = "args[0]"
      value = "--kubelet-insecure-tls"
    },
    {
      name  = "args[1]"
      value = "--kubelet-preferred-address-types=InternalIP"
    }
  ]
}
