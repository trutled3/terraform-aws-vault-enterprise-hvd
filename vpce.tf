resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.net_vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.net_lb_subnet_ids
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    var.resource_tags,
    { Name = "${var.friendly_name_prefix}-ssm-vpce" }
  )
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.net_vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.net_lb_subnet_ids
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    var.resource_tags,
    { Name = "${var.friendly_name_prefix}-ssmmessages-vpce" }
  )
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = var.net_vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.net_lb_subnet_ids
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = merge(
    var.resource_tags,
    { Name = "${var.friendly_name_prefix}-ec2messages-vpce" }
  )
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.friendly_name_prefix}-vpce-sg"
  description = "Security group for Vault VPC endpoints"
  vpc_id      = var.net_vpc_id

  tags = merge(
    var.resource_tags,
    { Name = "${var.friendly_name_prefix}-vpce-sg" }
  )
}

resource "aws_security_group_rule" "vpc_endpoints_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.main[0].id
  security_group_id        = aws_security_group.vpc_endpoints.id
  description              = "Allow HTTPS from main security group"
}
