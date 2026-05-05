resource "aws_security_group" "alb" {
  name = "${var.project_name}-${environment}-alb-sg"
  description = "ALB Security Group"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP inbound"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_block = "0.0.0.0/0"
  }

  ingress { 
    description = "HTTPS inbound"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_block = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_web" {
  name = "${var.project_name}-${environment}-web-sg"
  description = "ECS Web Security Group"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP ALB inbound"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All Outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-sg"
  }
}

resource "aws_security_group" "ecs_app" {
  name = "${var.project_name}-${var.environment}-app-sg"
  description = "ECS App Security Group"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "ECS Web inbound"
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    security_groups = [aws_security_group.ecs_app.id]
  }

  egress {
    description = "All outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-sg"
  }
}

resource "aws_security_group" "lambda" {
  Name = "${var.project_name}-${var.environment}-lambda"
  description = "Lambda Security Group"
  vpc_id = aws_vpc.main.id

  egress {
    description = "All outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "proxy" {
  Name = "${var.project_name}-${var.environment}-proxy"
  description = "Proxy Security Group"
  vpc_id = aws_vpc.main_id

  ingress {
    description = "ECS App to Proxy"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [
      aws_security_group.ecs_app.id,
      aws_security_group.lambda.id
    ]
  }

  egress {
    description = "All outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-proxy"
  }
}

resource "aws_security_group" "rds" {
  Name = "${var.project_name}-${var.environment}-rds"
  description = "RDS Security Group"
  vpc_id = aws_vpc.main.id

  ingress { 
    description = "Proxy to Rds"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.proxy.id]
  }

  egress {
    description = "All outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds"
  }
}

resource "aws_security_group" "cache" {
  Name = "${var.project_name}-${var.environment}-cache"
  description = "Cache Security Group"
  vpc_id = aws_vpc.main.id

  ingress { 
    description = "ECS App to Cache"
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_groups = [
      aws_security_group.ecs_app.id,
      aws_security_group.lambda.id
    ]
  }

  egress {
    description = "All outbound"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cache"
  }
}

