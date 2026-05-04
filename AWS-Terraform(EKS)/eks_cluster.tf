resource "aws_eks_cluster" "main" {
    name = "${var.project_name}-${var.environment}-eks-cluster"
    role_arn = aws_iam_role.eks_cluster.arn
    version = "1.32"

    vpc_config {
        subnets = [for subnet in aws_subnet.private : subnet.id]
        enable_private_access = true
        enable_public_access = false    
    }

    enabled_cluster_log_types = [
        "api"
        "audit"
        "authenticator"
        "controllerManager"
        "scheduler"
    ]

    encryption_config {
        provider {
            key_arn = aws_kms_key.main.arn
        }

        resources = ["secrets"]
    }

    depends_on = [aws_iam_role_policy_attachment.eks_cluster]

    tags = {
        Name = "${var.project_name}-${var.environment}-eks-cluster"
    }
}