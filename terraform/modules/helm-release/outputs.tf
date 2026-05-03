# /modules/helm-release/outputs.tf

output "name" {
  description = "Helm release name"
  value       = helm_release.this.name
}

output "namespace" {
  description = "Kubernetes namespace"
  value       = helm_release.this.namespace
}

output "version" {
  description = "Installed chart version"
  value       = helm_release.this.version
}

output "status" {
  description = "Release status (deployed/failed/etc.)"
  value       = helm_release.this.status
}
