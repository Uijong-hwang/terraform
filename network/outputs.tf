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