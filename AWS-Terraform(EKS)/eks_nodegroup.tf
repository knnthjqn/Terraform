resource "aws_launch_template" "eks_nodes" {
    name = "${var.project_name}-${var.environment}-eks-nodes-template"
    image_id = data.aws_ami.al2023.id

    vpc_security_group_ids = [aws_security_group.eks_nodes.id]

    block_device_mappings {
        device_name = "/dev/xvda"

        ebs {
            volume_type = "gp3"
            volume_size = 20
            encrypted = true
            kms_key_id = aws_kms_key.main.id
            delete_on_termination = true
        }
    } 
    
    metadata_options {
        http_tokens = "required"
    }

    monitoring {
        enabled = true
    }

    tags = {
        Name = "${var.project_name}-${var.environment}-eks-nodes-template"
    }
}

resource "aws_eks_note_group" "general" {
    node_group_name = "${var.project_name}-${var.environment}-eks-nodes-general"
    cluster_name = aws_eks_cluster.main.name
    node_role_arn = aws_iam_role.eks_nodes.arn


    subnet_ids = [for subnet in private.subnet : subnet.id]
    instance_types = ["t3.large"]
    ami_type = "AL2023_x86_64_STANDARD"
    capacity_type = "ON_DEMAND"

    launch_template {
        id = aws_launch_template.eks_nodes.id
        version = "$Latest"
    }

    scaling_config {
        min_size = 2
        desired_size = 2
        max_size = 4
    }

    update_config {
        max_unavailable = 1
    }

    depends_on = [
        aws_iam_role_policy_attachment.eks_worker_nodes,
        aws_iam_role_policy_attachment.eks_cni,
        aws_iam_role_policy_attachment.eks_ecr_pull
    ]

    tags = {
        name = "${var.project_name}-${var.environment}-eks-nodes-general"
    }
}
