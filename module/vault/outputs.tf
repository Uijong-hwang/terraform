output "vault_lb_domain" {
  value       = aws_lb.vault.dns_name
  description = "Vault ALB DNS 이름"
}

output "vault_lb_zone_id" {
  value       = aws_lb.vault.zone_id
  description = "Vault ALB Zone ID"
}

output "vault_active_instance_id" {
  value       = aws_instance.vault_instance_active.id
  description = "Vault Active Instance ID"
}

output "vault_key" {
  value       = aws_kms_key.vault_key.key_id
  description = "Vault Sealing key"
}

output "vault_active_instance_ip" {
  value       = aws_instance.vault_instance_active.private_ip
  description = "Vault Active Instance private IP"
}

output "vault_ssm_name" {
  value       = aws_ssm_document.vault.name
  description = "Vault SSM Document Name"
}