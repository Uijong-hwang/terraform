# 요구되는 테라폼 제공자 목록
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

# backend configuration
terraform {
  backend "s3" {
    bucket = "uijong-terraform"
    key   = "network/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "uijong-terraform"
    encrypt = true
  }
}