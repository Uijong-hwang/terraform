# Vault ALB 
resource "aws_lb" "vault" {
  name  = "${var.name}-lb"
  internal = var.internal
  load_balancer_type = "application"
  security_groups = compact([aws_security_group.vault_alb.id,try(var.additional_security_group, "")])
  subnets = var.public_subnets
}

# ALB SG
resource "aws_security_group" "vault_alb" {
  name = "${var.name}-alb-sg"
  vpc_id = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# ALB SG Rule 443
resource "aws_security_group_rule" "vault_alb" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = var.alb_ingress_cidr_blocks
  security_group_id = aws_security_group.vault_alb.id
}

# Vault Target Group
resource "aws_lb_target_group" "vault" {
  name = "vault-tg-8200"
  port = 8200
  protocol = "HTTP"
  vpc_id = var.vpc_id

  health_check {
    path = "/v1/sys/health"
    port = 8200
  }
}

# ALB 에 443 리스너 추가
resource "aws_lb_listener" "vault_443" {
  load_balancer_arn = aws_lb.vault.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault.arn
  }
}

# ALB 에 80 리스너 추가
resource "aws_lb_listener" "vault_80" {
  load_balancer_arn = aws_lb.vault.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "redirect" # redirect https
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# EC2에 적용할 Role 생성
resource "aws_iam_role" "vault_role" {
  name = "VaultRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.vault_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_policy" "allow_kms_usage" {
  name        = "VaultKMSUsage"
  path        = "/"
  description = "Allows usage of KMS key"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "${aws_kms_key.vault_key.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "allow_kms_usage_attachment" {
  role       = aws_iam_role.vault_role.name
  policy_arn = aws_iam_policy.allow_kms_usage.arn
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "ssm_instance_profile"
  role = aws_iam_role.vault_role.name
}

resource "aws_security_group" "vault_ec2" {
  name = "${var.name}-ec2-sg"
  vpc_id = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group_rule" "vault_ing_alb" {
  type = "ingress"
  from_port = 8200
  to_port = 8200
  protocol = "tcp"
  source_security_group_id = aws_security_group.vault_alb.id
  security_group_id = aws_security_group.vault_ec2.id
}

resource "aws_security_group_rule" "vault_ec2" {
  type = "ingress"
  from_port = 8200
  to_port = 8201
  protocol = "tcp"
  source_security_group_id = aws_security_group.vault_ec2.id
  security_group_id = aws_security_group.vault_ec2.id
}

# Create KMS key
resource "aws_kms_key" "vault_key" {
  description             = "For vault unsealing"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_instance" "vault_instance_active" {
  ami = data.aws_ami.amazon-linux-2.id
  instance_type = var.instance_type

  subnet_id = element(var.private_subnets, 0)

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  vpc_security_group_ids = [aws_security_group.vault_ec2.id]

  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }

  tags = {
    Name = "Vault-Active"
  }
}

resource "aws_instance" "vault_instance_standby" {
  count = 2
  ami = data.aws_ami.amazon-linux-2.id
  instance_type = var.instance_type

  subnet_id = element(var.private_subnets, count.index+1)

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  vpc_security_group_ids = [aws_security_group.vault_ec2.id]

  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }

  tags = {
    Name = "Vault-Standby-${count.index+1}"
  }
}

resource "aws_ssm_document" "vault" {
  name          = "vault"
  document_type = "Command"

  content = templatefile("${path.module}/vault_install_script/ssm_document.json.tpl", {
    run_command = jsonencode(split("\n", templatefile("${path.module}/vault_install_script/vault.sh", {
      LB_DOMAIN = "${aws_lb.vault.dns_name}"
      AWS_REGION = "ap-northeast-2"
      KMS_KEY = "${aws_kms_key.vault_key.key_id}"
      LEADER_IP = "${aws_instance.vault_instance_active.private_ip}"
    })))
  })
}

resource "aws_ssm_association" "vault_active" {
  name = aws_ssm_document.vault.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.vault_instance_active.id]
  }
}

resource "aws_ssm_association" "vault_standby" {
  count = length(aws_instance.vault_instance_standby.*.id)
  name = aws_ssm_document.vault.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.vault_instance_standby[count.index].id]
  }

  depends_on = [
    aws_ssm_association.vault_active
  ]
}

resource "aws_lb_target_group_attachment" "vault_active" {
  target_group_arn = aws_lb_target_group.vault.arn
  target_id        = aws_instance.vault_instance_active.id
  port             = 8200
}

resource "aws_lb_target_group_attachment" "vault_standby" {
  count            = length(aws_instance.vault_instance_standby.*.id)
  target_group_arn = aws_lb_target_group.vault.arn
  target_id        = aws_instance.vault_instance_standby[count.index].id
  port             = 8200
}