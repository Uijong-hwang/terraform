module "vault" {
  source                  = "../module/vault"
  name                    = "vault"
  internal                = false
  public_subnets          = data.terraform_remote_state.network.outputs.public_subnet_ids
  private_subnets         = data.terraform_remote_state.network.outputs.private_subnet_ids
  vpc_id                  = data.terraform_remote_state.network.outputs.vpc_id
  alb_ingress_cidr_blocks = ["0.0.0.0/0"]
  certificate_arn         = data.terraform_remote_state.network.outputs.uijong_acm_arn
}