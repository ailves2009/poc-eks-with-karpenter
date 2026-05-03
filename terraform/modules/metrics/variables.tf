# modules/metrics/variables.tf

variable "kube_host" {
  description = "Kubernetes API server endpoint"
  type        = string
}

variable "kube_ca" {
  description = "Base64 encoded CA certificate for the Kubernetes cluster"
  type        = string
  sensitive   = true
}

variable "kube_token" {
  description = "Bearer token for Kubernetes API authentication"
  type        = string
  sensitive   = true
}
#--
variable "metrics_server_helm_version" {
  description = "metrics-server helm version"
  type        = string
  default     = "3.8.2"
}

variable "metrics_server_namespace" {
  description = "metrics-server install namespace"
  type        = string
  default     = "kube-system"
}

variable "metrics_server_helm_repo" {
  description = "metrics-server helm repository"
  type        = string
  default     = "https://kubernetes-sigs.github.io/metrics-server"
}

variable "metrics_server_settings" {
  description = "metrics-server base settings"
  type        = map(any)
  default = {
    # "podAnnotations.custom\\.annotation\\.io" = "test"
    # "podAnnotations.environment"              = "test"
    # "metrics.enabled"                         = "true"
    "args[0]" = "--kubelet-insecure-tls"
    "args[1]" = "--kubelet-preferred-address-types=InternalIP"
  }
}
