resource "aws_launch_template" "web" {
    name = "${var.project_name}-web-lt"
    image_id = data.aws_ami.al2023.id
    instance_type = "t3.micro"

    iam_instance_profile {
        name = aws_iam_instance_profile.web.name
    }

    vpc_security_group_id = aws_security_group.web.id

    user_data = base64encode(<<-EOF
        #!/bin/bash
        dnf update -y
        dnf install -y nginx
        systemctl enable nginx
        systemctl start nginx
    EOF)
}

resource "aws_launch_template" "app" {
    name = "${var.project_name}-app-lt"
    image_id = data.aws_ami.al2023.id
    instance_type = "t3.micro"

    iam_instance_profile {
        name = aws_iam_instance_profile.app.id
    }

    vpc_security_group_id = aws_security_group.app.id

    user_data = base64encode(<<-EOF
        #!/bin/bash
        dnf update -y
        dnf install -y python3 unzip awscli
        mkdir -p /opt/app
    EOF)
}

resource "aws_autoscaling_group" "web" {
    name = "${var.project_name}-web-asg"
    min_size = 2
    desired_capacity = 2
    max_size = 4
    vpc_subnet_ids = [for subnet in aws_subnet.private : subnet.id]
    health_check_type = "ELB"

    launch_template {
        id = aws_launch_template.web.id
        version = "$Latest"
    }

    tag {
        Key = "Name"
        value = "${var.project_name}-web-asg"
        propagate_at_launch = true
    }

    tag {
        key = "Role"
        value = "Web"
        propagate_at_launch = true
    }
}

resource "aws_autoscaling_group" "app" {
    name = "${var.project_name}-app-asg"
    min_size = 2
    desired_capacity = 2
    max_size = 4
    vpc_subnet_ids = [for subnet in aws_subnet.private : subnet.id]
    health_check_type = "ELB"

    launch_template {
        id = aws_launch_template.app.id
        version = "$Latest"
    }

    tag {
        key = "Name"
        value = "${var.project_name}-app-asg"
        propagate_at_launch = true
    }

    tag {
        key = "Role"
        value = "App"
        propagate_at_launch = true
    }
}
