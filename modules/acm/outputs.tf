# /modules/acm/outputs.tf

output "wildcard_certificate_arn" {
  value = aws_acm_certificate.wildcard.arn
  # *.poc-eks-karpenter.domain.xyz
}

# Monitoring outputs
output "cloudwatch_alarm_arn" {
  description = "ARN of the CloudWatch alarm for certificate expiry"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.certificate_expiry[0].arn : null
  # arn:aws:cloudwatch:eu-west-3:111122223333:alarm:acm-certificate-expiry-poc-eks-karpenter-domain-xyz
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for certificate alerts"
  value       = var.create_sns_topic && length(var.alarm_email) > 0 ? aws_sns_topic.certificate_alerts[0].arn : null
  # arn:aws:sns:eu-west-3:111122223333:acm-certificates
}

output "dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = var.enable_monitoring ? "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.id}#dashboards:name=${aws_cloudwatch_dashboard.certificate_monitoring[0].dashboard_name}" : null
  # https://console.aws.amazon.com/cloudwatch/home?region=eu-west-3#dashboards:name=acm-certificates-poc-eks-karpenter-domain-xyz
}

output "aws_cloudwatch_metric_alarm-certificate_critical_expiry" {
  description = "CloudWatch alarm for critical certificate expiry"
  value       = var.enable_monitoring ? aws_cloudwatch_metric_alarm.certificate_critical_expiry[0].alarm_actions : null
  # arn:aws:sns:eu-west-3:111122223333:acm-certificates
}
