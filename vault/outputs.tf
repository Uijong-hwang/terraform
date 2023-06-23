output "vault_lb_domain" {
  value       = module.vault.vault_lb_domain
  description = "Vault ALB DNS 이름"
}

output "vault_lb_zone_id" {
  value       = module.vault.vault_lb_zone_id
  description = "Vault ALB Zone ID"
}
