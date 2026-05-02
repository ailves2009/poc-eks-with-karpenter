# modules/iam/outputs.tf

output "role_arn" {
  description = "ARN cicd-deployment-role"
  value       = aws_iam_role.deploy_assume_role.arn
}

