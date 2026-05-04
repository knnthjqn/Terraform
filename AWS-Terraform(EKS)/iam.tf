resource "aws_iam_role" "eks_cluster" {
    name = "${var.project_name}-${var.environment}-eks-cluster-role"

    assume_role_policy = jsonencode ({
        Statement = [{
            Effect = "Allow",
            Principals = { Service = "eks.amazonaws.com" },
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    role = aws_iam_role.eks_cluster.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_nodes" {
    name = "${var.project_name}-${var.environment}-eks-nodes-role"

    assume_role_policy = jsonencode ({
        Statement = [{
            Effect = "Allow",
            Principals = { Service = "ec2.amazonaws.com" },
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "eks_worker_nodes" {
    role = aws_iam_role.eks_nodes.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
    role = aws_iam_role.eks_nodes.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_pull" {
    role = aws_iam_role.eks_nodes.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_role" "eks_app_pod" {
    name = "${var.project_name}-${var.environment}-eks-app-pod-role"

    assume_role_policy = jsonencode ({
        Statement = [{
            Effect = "Allow",
            Principals = { Service = "pods.eks.amazonaws.com" },
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy" "eks_app_pod" {
    name = "${var.project_name}-${var.environment}-eks-app-pod-policy"
    role = aws_iam_role.eks_app_pod.id

    policy = jsonencode ({
        Statement = [
            {
                Effect = "Allow",
                Actions = [
                    "dynamodb:GetItem",
                    "dynamodb:PutItem",
                    "dynamodb:UpdateItem",
                    "dynamodb:DeleteItem",
                    "dynamodb:Scan",
                    "dynamodb:Query"
                ],
                Resource = aws_dynamodb_table.app.arn
            },
            {
                Effect = "Allow",
                Actions = [
                    "secretsmanager:GetSecretValue",
                    "secretsmanager:DescribeSecret"
                ],
                Resource = aws_secretsmanager_secret.db.arn
            },
            {
                Effect = "Allow",
                Actions = [
                    "kms:Decrypt"
                ],
                Resource = aws_kms_key.main.arn
            },
            {
                Effect = "Allow",
                Actions = [
                    "s3:GetObject",
                    "s3:ListBucket"
                ],
                Resources = [aws_s3_bucket.media.arn, "${aws_s3_bucket.media.arn}/*"]
            }
        ]
    })
}

resource "aws_iam_role" "rds_proxy" {
    name = "${var.project_name}-${var.environment}-rds-proxy-role"

    assume_role_policy = jsonencode ({
        Statement = [{
            Effect = "Allow",
            Principals = { Service = "rds.amazonaws.com },
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy" "rds_proxy" {
    name = "${var.project_name}-${var.environment}-rds-proxy-policy"
    role = aws_iam_role.rds_proxy.id

    policy = jsonencode ({
        Statement = [
            {
                Effect = "Allow",
                Actions = [
                    "secretsmanager:GetSecretValue"
                ],
                Resource = aws_secretsmanager_secret.db.arn
            },
            {
                Effect = "Allow",
                Actions = [
                    "kms:Decrypt"
                ],
                Resource = aws_kms_key.main.arn
            }
        ]
    })
}