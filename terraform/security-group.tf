# Nombres de recursos con prefijo tfv_* para no chocar con state legado (grupo1 / allow_ssh_ipv4, etc.)

resource "aws_security_group" "ec2" {
  name        = "tfv-ec2-sg"
  description = "TFV: SSH 22, Vue/nginx 8080, Nest 3000, HTTP/S; stack Node (sin JVM)"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "tfv-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "tfv_ec2_in_ssh_v4" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "tfv_ec2_in_ssh_v6" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv6         = "::/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "tfv_ec2_in_8080_v4" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_ingress_rule" "tfv_ec2_in_8080_v6" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv6         = "::/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_ingress_rule" "tfv_ec2_in_3000_v4" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}

resource "aws_vpc_security_group_ingress_rule" "tfv_ec2_in_3000_v6" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv6         = "::/0"
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}

resource "aws_vpc_security_group_ingress_rule" "tfv_ec2_in_80_v4" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "tfv_ec2_in_80_v6" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv6         = "::/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "tfv_ec2_in_443_v4" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "tfv_ec2_in_443_v6" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv6         = "::/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "tfv_ec2_eg_all_v4" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "tfv_ec2_eg_all_v6" {
  security_group_id = aws_security_group.ec2.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "rds" {
  name        = "tfv-rds-sg"
  description = "PostgreSQL 5432 desde EC2 y desde ${var.rds_ingress_cidr}"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "tfv-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "tfv_rds_in_pg_v4" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = var.rds_ingress_cidr
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

resource "aws_vpc_security_group_ingress_rule" "tfv_rds_in_pg_v6" {
  count             = var.rds_allow_ipv6 ? 1 : 0
  security_group_id = aws_security_group.rds.id
  cidr_ipv6         = "::/0"
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

resource "aws_vpc_security_group_ingress_rule" "tfv_rds_in_from_ec2" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ec2.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

resource "aws_vpc_security_group_egress_rule" "tfv_rds_eg_all_v4" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
