resource "aws_lb" "web" {
    name = "${var.project_name}-web-lb"
    internal = false
    load_balancer_type = "Application"
    subnets = [for subnet in aws_subnet.public : subnet.id]
    security_group = aws_security_group.web_alb.id
    enable_deletion_protection = true
    drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "web" {
    name = "${var.project_name}-web-tg"
    port = 80
    protocol = "http"
    target_type = "instance"
    vpc_id = aws_vpc.main.id
    deregistration_delay = 30

    health_check {
        enabled = true
        matcher = "200-399"
        interval = 30
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener" "web_http" {
    load_balancer_arn = aws_lb.web.arn
    port = 80
    protocol = "http"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.web.arn
    }
}

resource "aws_lb" "app" {
    name = "${var.project_name}-app-lb"
    internal = true
    load_balancer_type = "Application"
    subnets = [for subnet in aws_subnet.private : subnet.id]
    security_group = aws_security_group.app_alb.id
}

resource "aws_lb_target_group" "app" {
    name = "${var.project_name}-app-tg"
    port = 80
    protocol = "http"
    target_type = "instance"
    vpc_id = aws_vpc.main.id
    deregistration_delay = 30

    health_check {
        enabled = true
        matcher = "200-399"
        interval = 30
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener" "app_http" {
    load_balancer_arn = aws_lb.web.arn
    port = 80
    protocol = "http"

    default_action {
        type = "forward"
        target_type_arn = aws_lb_target_group.app.arn
    }
}
