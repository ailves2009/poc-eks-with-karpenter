# /modules/helm-release/variables.tf

# --- Helm release ---------------------------------------------------------

variable "name" {
  description = "Helm release name"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "create_namespace" {
  description = "Whether Helm should create the namespace if it does not exist"
  type        = bool
  default     = true
}

variable "chart" {
  description = "Helm chart name (e.g. \"nginx\") or OCI ref"
  type        = string
}

variable "repository" {
  description = "Chart repository URL. Set to null for local charts; for OCI use \"oci://...\""
  type        = string
  default     = null
}

variable "chart_version" {
  description = "Chart version to install. Pin explicitly — never let helm pick \"latest\"."
  type        = string
}

variable "values" {
  description = "Helm values as a Terraform object. yamlencoded into the release."
  type        = any
  default     = {}
}

variable "values_yaml" {
  description = "Additional raw YAML values (list of strings). Applied AFTER `values` — useful for complex templated strings."
  type        = list(string)
  default     = []
}

variable "atomic" {
  description = "If true, release is rolled back on failure"
  type        = bool
  default     = true
}

variable "wait" {
  description = "Wait for all resources to become ready before returning"
  type        = bool
  default     = true
}

variable "timeout" {
  description = "Helm install/upgrade timeout (seconds)"
  type        = number
  default     = 300
}

# --- EKS provider auth ----------------------------------------------------

variable "cluster_name" {
  description = "EKS cluster name (for `aws eks get-token` exec auth)"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS API server endpoint"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 EKS CA"
  type        = string
}

variable "region" {
  description = "AWS region (for the exec block)"
  type        = string
}
