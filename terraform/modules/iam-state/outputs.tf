# /modules/iamstate/outputs.tf

output "deploy_role_arn" {
  description = "ARN cicd-role"
  value       = aws_iam_role.deploy_assume_role.arn
}

output "permissions_boundary_arn" {
  description = "ARN of the permissions boundary policy. Attach to every IAM role created downstream via `permissions_boundary = ...`."
  value       = aws_iam_policy.cicd_boundary.arn
}
