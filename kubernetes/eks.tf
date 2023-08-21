## Dependancy 문제가 있기 때문에 각 모듈을 순차적으로 하나씩 apply 해야함

module "eks" {
  source = "../module/kubernetes/eks"

  cluster_name    = local.env
  cluster_version = "1.27"
  vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
  vpc_subnet_ids  = data.terraform_remote_state.network.outputs.public_subnet_ids
  endpoint_private_access = true
  endpoint_public_access = true
}

module "nodegroup" {
  source = "../module/kubernetes/eks-ng"

  cluster_name    = module.eks.cluster_id
  cluster_version = module.eks.cluster_version
  name            = "mng"
  subnet_ids      = data.terraform_remote_state.network.outputs.public_subnet_ids

  instance_types = ["m5.large"]
  max_size       = 5
  min_size       = 1

  user_data = <<USERDATA
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -ex

sudo amazon-linux-extras install docker -y

systemctl enable docker
systemctl restart docker

--==MYBOUNDARY==--
USERDATA
}

# EKS Add-on
module "eks_addon" {
  source = "../module/kubernetes/eks-addon"

  cluster_name        = module.eks.cluster_id
  cluster_oidc_issuer = module.eks.cluster_oidc_provider

  vpc_cni_version        = "v1.12.5-eksbuild.2"
  coredns_version        = "v1.10.1-eksbuild.1"
  ebs_csi_driver_version = "v1.19.0-eksbuild.1"
}

module "eks_common" {
  source = "../module/kubernetes/eks-common"

  cluster_name        = module.eks.cluster_id
  cluster_oidc_issuer = module.eks.cluster_oidc_provider

  public_subnet_ids  = data.terraform_remote_state.network.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids

  metric_server_chart_version                = "3.10.0"
  cluster_autoscaler_chart_version           = "9.29.1"
  external_dns_chart_version                 = "1.13.0"
  aws_load_balancer_controller_chart_version = "1.5.3"
  aws_load_balancer_controller_app_version   = "v2.5.2"
  nginx_ingress_controller_chart_version     = "4.7.0"

  external_dns_domain_filters = ["papershouse.site"]
  external_dns_role_arn       = module.irsa_external_dns.role_arn
  hostedzone_type             = "public"
  acm_certificate_arn         = data.terraform_remote_state.network.outputs.acm_arn

  depends_on = [
    module.nodegroup
  ]
}

module "irsa_external_dns" {
  source = "../module/kubernetes/eks-irsa"

  name                = "external-dns"
  namespace           = "kube-system"
  cluster_name        = module.eks.cluster_id
  cluster_oidc_issuer = module.eks.cluster_oidc_provider
  create_iam_role_only = true
  policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}