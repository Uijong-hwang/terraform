module "eks" {
  source = "../module/kubernetes/eks"

  cluster_name    = local.env
  cluster_version = "1.26"
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

  instance_types = ["m5.2xlarge"]
  max_size       = 10
  min_size       = 2

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
  coredns_version        = "v1.9.3-eksbuild.2"
  ebs_csi_driver_version = "v1.18.0-eksbuild.1"

  depends_on = [
    module.nodegroup
  ]
}