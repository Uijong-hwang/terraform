output "vault_lb_domain" {
  value       = aws_lb.vault.dns_name
  description = "Vault ALB DNS 이름"
}

output "vault_lb_zone_id" {
  value       = aws_lb.vault.zone_id
  description = "Vault ALB Zone ID"
}
