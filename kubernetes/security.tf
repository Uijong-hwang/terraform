# EKS 클러스터 외부 접근
resource "aws_security_group_rule" "from_mng_to_eks" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.eks.additional_security_group
}