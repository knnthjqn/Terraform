resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for internet-facing ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound to web tier"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

resource "aws_security_group" "ecs_web" {
  name = "${var.project_name}-${var.environment}-ecs-web"
  description = "ECS Web Security Group"
  vpc_id = vpc.main.id

  ingress {
    protocol = "HTTP from ALB"
    port = 8080
    from_port = 8080
    protocol = "tcp"
    cidr_block = aws_security_group.alb.id
  }

  egress {
    protocol = "All Outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-web"
  }
}

resource "aws_security_group" "ecs_app" {
  name = "${var.project_name}-${var.environment}-ecs-app"
  description = "ECS Web Security Group"
  vpc_id = vpc.main.id

  ingress {
    protocol = "Traffic from ECS Web"
    port = 9000
    from_port = 9000
    protocol = "tcp"
    cidr_block = aws_security_group.web.id
  }

  egress {
    protocol = "All Outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-app"
  }
}

resource "aws_security_group" "proxy" {
  name = "${var.project_name}-${var.environment}-proxy-sg"
  description = "Proxy Security Group"
  vpc_id = vpc.main.id

  ingress {
    description = "App to Proxy"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_block = aws_security_group.ecs_app.id
  }

  egress {
    description = "All Outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name = "${var.project_name}-${var.environment}-rds-sg"
  description = "RDS Security Group"
  vpc_id = vpc.main.id

  ingress {
    description = "Proxy to RDS"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_block = aws_security_group.proxy.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

resource "aws_security_group" "cache" {
  name = "${var.project_name}-${var.environment}-cache-sg"
  description = "Cache Security Group"
  vpc_id = vpc.main.id

  ingress {
    description = "App to Cache"
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    cidr_block = aws_security_group.app.sg
  }
}