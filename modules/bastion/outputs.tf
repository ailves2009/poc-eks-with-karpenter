# /modules/bastion/outputs.tf

output "public_ip" {
  description = "Bastion Elastic IP"
  value       = aws_eip.bastion.public_ip
}

output "dns_name" {
  description = "Public DNS record for the bastion (null when create_dns_record=false)"
  value       = var.create_dns_record ? aws_route53_record.bastion[0].fqdn : null
}

output "instance_id" {
  description = "EC2 instance ID (for SSM Session Manager)"
  value       = aws_instance.bastion.id
}

output "security_group_id" {
  description = "Bastion SG ID — reference from workload modules to allow ingress from the bastion (e.g. from-bastion-to-EKS-API rules)"
  value       = aws_security_group.bastion.id
}
