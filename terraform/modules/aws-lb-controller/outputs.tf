# /modules/aws-lb-controller/outputs.tf

output "iam_role_arn" {
  description = "IRSA role ARN attached to the controller's ServiceAccount"
  value       = module.irsa.iam_role_arn
}

output "iam_role_name" {
  description = "IRSA role name"
  value       = module.irsa.iam_role_name
}
