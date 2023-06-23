variable "name" {
    default     = "vault"
    description = "생성될 리소스 대표 이름"
    type        = string
}

variable "internal" {
    default     = false
    description = "생성될 ALB의 내부/외부 설정"
    type        = bool
}

variable "public_subnets" { 
    description = "생성될 리소스의 Public 서브넷 List"
    type        = list
}

variable "private_subnets" { 
    description = "생성될 리소스의 Private 서브넷 List"
    type        = list
}

variable "vpc_id" { 
    description = "생성될 리소스의 VPC ID"
    type        = string
}

variable "alb_ingress_cidr_blocks" {
    default     = ["0.0.0.0/0"]
    description = "ALB의 보안그룹의 inbound에 포함될 CIDR"
    type        = list
}

variable "certificate_arn" {
    description = "ALB Listener에 적용할 ACM"
    type        = string
}

variable "additional_security_group" {
    default     = null
    description = "ALB에 적용될 추가 보안 그룹 ID"
    type        = string
}

variable "instance_type" {
    default     = "t3.small"
    description = "Vault 인스턴스의 타입"
    type        = string
}

variable "region" {
    default     = "ap-northeast-2"
    description = "생성될 AWS Region"
    type        = string
}

# variable "" {
#     default     =
#     description = ""
#     type        = 
# }