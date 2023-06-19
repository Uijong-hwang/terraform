module "vpc" {
	source = "../module/network/vpc"

	# Required variables
	cidr = "10.0.0.0/16"
	name = "mng"

	# Optional variables
	# tags = {}
}

module "public_subnet" {
	source = "../module/network/subnet"

	# Required variables
	azs = data.aws_availability_zones.azs.names
	cidr = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
	prefix = local.env
	suffix = "sb-public"
	type = "public"
	vpc_id = module.vpc.vpc_id

	# Optional variables
	gateway_id = module.vpc.igw_id
	# nat_gateway_id = ""
	# tags = {}
}

module "private_subnet" {
	source = "../module/network/subnet"

	# Required variables
	azs = data.aws_availability_zones.azs.names
	cidr = ["10.0.10.0/24","10.0.20.0/24","10.0.30.0/24"]
	prefix = local.env
	suffix = "sb-private"
	type = "private"
	vpc_id = module.vpc.vpc_id

	# Optional variables
	# gateway_id = 
	nat_gateway_id = module.nat_gateway.id
	# tags = {}
}

module "nat_gateway" {
	source = "../module/network/nat"

	# Required variables
	name = local.env
	subnet_id = module.public_subnet.subnet_ids[0]

	# Optional variables
	# tags = {}
}

resource "aws_route53_zone" "uijong" {
  name = "uijong.site"
}

resource "aws_acm_certificate" "uijong" {
  domain_name = "*.uijong.site"
  validation_method = "DNS"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "uijong_acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.uijong.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = aws_route53_zone.uijong.zone_id
}