# /modules/karpenter/versions.tf

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
    # gavinbunney/kubectl handles applying CRs whose CRDs were just installed —
    # cleaner than hashicorp/kubernetes_manifest, which insists on the API
    # server already knowing the kind at plan time.
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}
