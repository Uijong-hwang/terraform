data "aws_availability_zones" "azs" {}

# S3에 저장된 상태정보를 통해서 Common 모듈 정보 불러오기
# data "terraform_remote_state" "common" {
#   backend = "s3"
#   config = {
#     bucket = "uijong-terraform"
#     key    = "common/terraform.tfstate"
#     region = "ap-northeast-2"
#   }
# }