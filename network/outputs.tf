output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
    value   = module.public_subnet.subnet_ids
    description = "public 서브넷 목록"
}

output "private_subnet_ids" {
    value   = module.private_subnet.subnet_ids
    description = "private 서브넷 목록"
}

output "nat_gateway_id" {
  value = module.nat_gateway.id
}

output "ns_record" {
  value = aws_route53_zone.this
  description = "생성된 도메인의 NS Record"
}

output "acm_arn" {
  value = aws_acm_certificate.this.arn
  description = "생성된 ACM ARN"
}

output "zone_id" {
  value = aws_route53_zone.this.zone_id
  description = "생성된 route53 호스팅 zone id"
}