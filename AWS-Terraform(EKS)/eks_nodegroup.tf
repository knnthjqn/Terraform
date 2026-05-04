resource "aws_launch_template" "eks_nodes" {
    name = "${var.project_name}-${var.environment}-eks-node-lt"
    image_id = data.aws_ami.al2023.id

    vpc_security_group_ids = [aws_security_group.eks_nodes.id]

    block_device_mappings {
        device_name = "/dev/xvda"

        ebs {
            volume_type = "gp3"
            volume_size = 40
            encrypted = true
            kms_key_id = aws_kms_key.main.id
            delete_on_termination = true
        }
    }

    metadata_options {
        http_endpoint = "enabled"
        hhtp_tokens = "required"
    }

    monitoring {
        enabled = true
    }

    tags = {
        name = "${var.project_name}-${var.environment}-eks-node-lt"
    }
}   

resource "aws_eks_node_group" "general" {
    name = "${var.project_name}-${var.environment}-eks-node-general"
    cluster_name = aws_eks_cluster.main.name
    node_role_arn = aws_iam_role.eks_node.arn
    subnet_ids = [for subnet in aws_subnet.private : subnet.id]
    instance_type = "t3.large"
    ami_type = "AL2023_x86_64_STANDARD"
    capacity_type = "ON_DEMAND"

    launch_template {
        id = aws_launch_template.eks_nodes.id
        version = "$Latest"
    }

    scaling_config {
        min_size = 2
        desired_size = 4
        max_size = 8
    }

    update_config {
        max_unavailable = 1
    }

    depends_on = [
        aws_iam_role_policy_attachment.eks_workder_nodes,
        aws_iam_role_policy_attachment.eks_cni,
        aws_iam_role_policy_attachment.eks_ecr_pull
    ]

    tags = {
        name = "${var.project_name}-${var.environment}-eks-node-general"
    }
}