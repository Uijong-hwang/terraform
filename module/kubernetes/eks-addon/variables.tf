variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
}

variable "cluster_oidc_issuer" {
  description = "EKS 클러스터 OIDC 제공자"
  type        = string
}

variable "vpc_cni_version" {
  description = "VPC CNI 버전"
  type        = string
}

variable "ebs_csi_driver_version" {
  description = "Amazon EBS CSI driver 버전"
  type        = string
}

variable "coredns_version" {
  description = "CoreDNS 버전"
  type        = string
}