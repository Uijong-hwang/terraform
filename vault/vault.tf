module "vault" {
  source                  = "../module/vault"
  name                    = "vault"
  internal                = false
  public_subnets          = data.terraform_remote_state.network.outputs.public_subnet_ids
  private_subnets         = data.terraform_remote_state.network.outputs.private_subnet_ids
  vpc_id                  = data.terraform_remote_state.network.outputs.vpc_id
  alb_ingress_cidr_blocks = ["0.0.0.0/0"]
  certificate_arn         = data.terraform_remote_state.network.outputs.acm_arn
}

# Vault ALB를 향하는 Route53 Record 생성
## module 이용하여 vault 생성 후 Record 생성해야함
resource "aws_route53_record" "vault_alb" {
	zone_id = data.terraform_remote_state.network.outputs.zone_id
	name 	= "vault.papershouse.site"
	type	= "A"

	alias {
		name = module.vault.vault_lb_domain
		zone_id = module.vault.vault_lb_zone_id
		evaluate_target_health = true
	} 
}