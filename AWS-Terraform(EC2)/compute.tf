resource "aws_launch_template" "web" {
    name = "${var.project_name}-${var.environment}-web-lt"
    image_id = data.aws_ami.al2023.id
    instance_type = "t3.small"

    iam_instance_profile {
        name = aws_iam_instance_profile.web.name
    }

    vpc_security_group_ids = [aws_security_group.web.id]

    user_data = base64encode (<<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx
    systemctl enabled nginx
    systemctl start nginx
    EOF)
}

resource "aws_launch_template" "app" {
    name = "${var.project_name}-${var.environment}-app-lt"
    image_id = data.aws_ami.al2023.id
    instance_type = "t3.small"

    iam_instance_profile {
        name = aws_iam_instance_profile.app.name
    }

    vpc_security_group_ids = [aws_security_group.app.id]

    user_data = base64encode (<<-EOF
        #!/bin/bash
        dnf update -y
        dnf install -y python3
    EOF)
}

resource "aws_autoscaling_group" "web" {
    name = "${var.project_name}-${var.environment}-web-asg"
    min_size = 2
    desired_capacity = 4
    max_size = 8
    vpc_subnet_ids = [for subnet in aws_subnet.private : subnet.id]

    launch_template {
        id = aws_launch_template.web.id
        version = "$Latest"
    }
}

resource "aws_autoscaling_group" "app" {
    name = "${var.project_name}-${var.environment}-web-asg"
    min_size = 2
    desired_capacity = 4
    max_size = 8
    vpc_subnet_ids = [for subnet in aws_subnet.private : subnet.id]

    launch_template {
        id = aws_launch_template.web.id
        version = "$Latest"
    }
}

resource "aws_lb" "internal" {
    name = "${var.project_name}-${var.environment}-internal-lb"
    internal = true
    load_balancer_type = "application"
    subnet_ids = [for subnet in aws_subnet.private : subnet.id]
    security_group_ids = [aws_security_group.internal_alb.id]
    enable_deletion_protection = true
    drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "web" {
    name = "${var.project_name}-${var.environment}-web-lb-tg"
    port = 80
    protocol = "HTTP"
    target_type = "instance"
    vpc_id = aws_vpc.main.id

    health_check {
        enabled = true
        path = "/"
        matcher = "200-399"
        interval = 30
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.internal.arn
    port = 80
    protocol = "http"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.web.arn"
    }
}

resource "aws_autoscaling_attachment" "web" {
    autoscaling_group_name = aws_autoscaling_group.web.name
    lb_target_group_arn = aws_lb_target_group.web.arn
}