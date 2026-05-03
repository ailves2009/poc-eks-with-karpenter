# /modules/karpenter/outputs.tf

output "controller_iam_role_arn" {
  description = "IRSA role ARN bound to the Karpenter controller's ServiceAccount"
  value       = module.karpenter.iam_role_arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN attached to nodes provisioned by Karpenter"
  value       = module.karpenter.node_iam_role_arn
}

output "node_iam_role_name" {
  description = "IAM role name (used in EC2NodeClass)"
  value       = module.karpenter.node_iam_role_name
}

output "queue_name" {
  description = "SQS queue receiving spot interruption notices via EventBridge"
  value       = module.karpenter.queue_name
}
