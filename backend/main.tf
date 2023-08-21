# 요구되는 테라폼 제공자 목록
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

## 초기 진행시 주석 처리후 terraform init 후에 백엔드 설정 진행 해야함
## 주석 해제 후 terraform init -migrate-state 
# backend configuration
terraform {
  backend "s3" {
    bucket = "uijong-terraform"
    key   = "backend/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "uijong-terraform"
    encrypt = true
  }
}