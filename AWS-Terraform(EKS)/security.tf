resource "aws_security_group" "apigw_vpc_link" {
  name = "${var.project_name}-${var.environment}-apigw-vpc-link-sg"
  description = "API Gateway VPC Link Security Group"
  vpc_id = aws_vpc.main.id

  egress {
    description = "VPC Link to Internal ALB"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    name = "${var.project_name}-${var.environment}-apigw-vpc-link"
  }
}

resource "aws_security_group" "internal_alb" {
  name = "${var.project_name}-${var.environment}-internal-alb-sg"
  description = "Internal ALB Security Group"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "API Gateway VPC Link to Internal ALB"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.apigw_vpc_link.id]
  }

  egress { 
    description = "Internal ALB to backend services"
    from_port = 0
    to_port = 0
    protocol = "-1'
    cidr_block = [var.vpc_cidr]
  }

  tags = {
    name = "${var.project_name}-${var.environment}-internal-alb-sg"
  }
}

resource "aws_security_group" "eks_nodes" {
  name = "${var.project_name}-${var.environment}-eks-nodes-sg"
  description = "EKS Nodes Security Group"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Note to Node communication"
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  ingress {
    description = "Internal ALB to NodePort"
    from_port = 30080
    to_port = 30080
    protocol = "tcp"
    security_group_ids = [aws_security_group.internal_alb.id]
  }

  egress {
    description = "All Outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    name "${var.project_name}-${var.environment}-eks-nodes-sg"
  }
}

resource "aws_security_group" "proxy" {
  name = "${var.project_name}-${var.environment}-proxy-sg"
  description = "Proxy Security Group"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "EKS Nodes to Proxy"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_group_ids = [aws_security_group.eks_nodes.id]
  }

  egress { 
    description = "All Outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = [var.vpc_cidr]
  }

  tags = {
      name = "${var.project_name}-${var.environment}-proxy-sg"
  }
}

resource "aws_security_group" "rds" {
  name = "${var.project_name}-${var.environment}-rds-sg"
  description = "RDS Security Group"
  vpc_id = aws_vpc.main.id

  ingress { 
    description = "Proxy to RDS"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_group_ids = [aws_security_group.proxy.id]
  }
  
  tags = {
    name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

resource "aws_security_group" "cache" {
  name = "${var.project_name}-${var.environment}-cache-sg"
  description = "Cache Security Group"
  vpc_id = aws_vpc.main.id

  ingress { 
    description = "EKS Nodes to Cache"
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_group_ids = [aws_security_group.eks_nodes.id]
  }

  tags = {
    name = "${var.project_name}-${var.environment}-cache-sg"
  }
}