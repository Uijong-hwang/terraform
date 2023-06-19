# 요구되는 테라폼 제공자 목록
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

# backend configuration
terraform {
  backend "s3" {
    bucket = "uijong-terraform"
    key   = "kubernetes/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "uijong-terraform"
    encrypt = true
  }
}