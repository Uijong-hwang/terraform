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

resource "aws_ssm_document" "vault_config" {
  name          = "vault"
  document_type = "Command"

  content = templatefile("${path.module}/vault_install_script/ssm_document.json.tpl", {
    run_command = jsonencode(split("\n", templatefile("${path.module}/vault_install_script/vault.sh", {
      LB_DOMAIN = "${aws_lb.vault.dns_name}"
      AWS_REGION = "ap-northeast-2"
      KMS_KEY = "${aws_kms_key.vault_key.key_id}"
      LEADER_IP = "${aws_instance.vault_instance_active.private_ip}"
    })))
  })
}

resource "aws_ssm_association" "vault_config" {
  name = aws_ssm_document.vault.name

  targets {
    key    = "InstanceIds"
    values = [module.vault.vault_active_instance_id]
  }
}