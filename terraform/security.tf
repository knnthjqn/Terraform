resource "aws_security_group" "apigw_vpc_link" {
    name = "${var.project_name}-${var.environment}-apigw-vpc-link-sg"
    vpc_id = aws_vpc.main.id

    egress { 
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_group = aws_security_group.web_lb.id
    }
}

resource "aws_security_group" "web_lb" {
    name = "${var.project_name}-${var.environment}-web-lb-sg"
    vpc_id = aws_vpc.main.id

    ingress { 
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_group = aws_security_group.apigw_vpc_link.id
    }

    egress { 
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_group = aws_security_group.web.id
    }
}

resource "aws_security_group" "web" {
    name = "${var.project_name}-${var.environment}-web-sg"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_group = aws_security_group.web.id
    }

    egress { 
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_block = "0.0.0.0/0"
    }
}

resource "aws_security_group" "app_lb" {
    name = "${var.project_name}-${var.environment}-app-lb-sg"
    vpc_id = aws_vpc.main.id

    ingress { 
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        security_group = "aws_security_group.web.id
    }

    egress { 
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        security_group = aws_security_group.app.id
    }
}

resource "aws_security_group" "app" {
    name = "${var.project_name}-${var.environment}-app-sg"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        security_group = aws_security_group.app_lb.id
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_block = "0.0.0.0/0"
    }
}

resource "aws_security_group" "proxy" {
    name = "${var.project_name}-${var.environment}-proxy-sg"
    vpc_id = aws_vpc.main.id

    ingress { 
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        security_group = aws_security_group.app.id
    }

    egress { 
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_group = aws_security_group.rds.id
    }
}

resource "aws_security_group" "rds" {
    name = "${var.project_name}-${var.environment}-rds-sg"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_group = aws_security_group.proxy.id
    }
}

resource "aws_security_group" "cache" {
    name = "${var.project_name}-${var.environment}-cache-sg"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 6379
        to_port = 6379
        protocol = "tcp"
        security_group = aws_security_group.app.id
    }
}