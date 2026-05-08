resource "aws_security_group" "apigw_vpc_link" {
    name = "${var.project_name}-apigw-vpc-link-sg"
    vpc_id = aws_vpc.main.id

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_block = [var.vpc_cidr]
    }
}

resource "aws_security_group" "internal_alb" {
    name = "${var.project_name}-internal-alb-sg"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = tcp"
        security_groups = [aws_security_group.apigw_vpc_link.id]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.web.id]
    }
}

resource "aws_security_group" "web" {
    name = "${var.project_name}-web-sg"
    vpc_id = aws_vpc.main.id

    ingress { 
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [aws_security_group.internal_alb.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_block = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "app" {
    name = "${var.project_name}-web-sg"
    vpc_id = aws_vpc.main.id

    ingress { 
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        security_groups = [aws_security_group.web.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_block = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "proxy" {
    name = "${var.project_name}-proxy-sg"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.app.id]
    }
}

resoure "aws_security_group" "rds" {
    name = "${var.project_name}-rds-sg"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.proxy.id]
    }
}

resource "aws_security_group" "cache" {
    name = "${var.project_name}-cache-sg"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 3306
        to_port = 3006
        protocol = "tcp"
        security_groups = [aws_security_group.app.id]
    }
}