# modules/metrics/outputs.tf

output "metrics_server_helm_release_name" {
  description = "The name of the metrics-server Helm release"
  value       = helm_release.metrics.metadata.name
}

output "metrics_server_helm_release_namespace" {
  description = "The namespace of the metrics-server Helm release"
  value       = helm_release.metrics.metadata.namespace
}

output "metrics_server_helm_release_version" {
  description = "The version of the metrics-server Helm release"
  value       = helm_release.metrics.version
}
