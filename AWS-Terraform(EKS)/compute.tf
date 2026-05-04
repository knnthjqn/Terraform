resource "aws_lb" "internal_api" {
    name = "${var.project_name}-${var.environment}internal-api-alb"
    internal = false
    load_balancer_type = "Application"
    subnets = [for subnet in aws_subnet.private : subnet.id]
    vpc_security_group_ids = [aws_security_group.internal_alb.id]
    enable_deletion_protection = true
    drop_invalid_header_fields = true

    tags= {
        name = "${var.project_name}-${var.environment}internal-api-alb"
    }
}

resource "aws_lb_target_group" "eks_app" {
    name = name = "${var.project_name}-${var.environment}-eks-app-lb-target-group"
    port = 30080
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

    deregistration_delay = 30   
    
    tags = {
        name = "${var.project_name}-${var.environment}-eks-app-lb-target-group"
    }
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.internal_api.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"

        target_group_arn = aws_lb_target_group.eks_app.arn
    }
}

resource "aws_autoscaling_attachment" "eks_nodes_to_tg" {
    autoscaling_group_name = aws_eks_node_group.general.resources[0].autoscaling_groups[0].name

    lb_target_group_arn = aws_lb_target_group.eks_app.arn
}