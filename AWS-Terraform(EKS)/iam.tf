data "aws_iam_policy_document" "lambda_assume_role" {
    statement {
        effect = "Allow"

        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }

        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "lambda_sns" {
    name = "${var.project_name}-${var.environment}-sns-role"
    assume_role_policy = aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_sns_basic" {
    role = aws_iam_role.lambda_sns.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_sns_vpc" {
    role = aws_iam_role.lambda_sns.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "lambda_sns_permissions" {
    statement {
        effect = "Allow"
        actions = [
            "dynamodb:PutItem",
            "dynamodb:UpdateItem"
        ]

        resources = [aws_dynamodb_table.app.arn]
    }
}

resource "aws_iam_role_policy" "lambda_sns_permissions" {
    name = "${var.project_name}-${var.environment}-sns-permissions"
    role = aws_iam_role.lambda_sns.id
    policy = data.aws_iam_policy_document.lambda_sns_permissions.json
}

resource "aws_iam_role" "lambda_api" {
    name = "${var.project_name}-${var.environment}-api-role"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_api_basic" {
    role = aws_iam_role.lambda_api.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_api_vpc" {
    role = aws_iam_role.lambda_api.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "lambda_api_permissions" {
    statement [
        {
            effect = "Allow",
            actions = [
                "dynamodb:BatchGetItem",
                "dynamodb:BatchPutItem",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:Scan",
                "dynamodb:Query"
            ],
            resources = [aws_dynamodb_table.app.arn]
        },
        {
            effect = "Allow",
            actions = [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ]
            resources = [aws_secretsmanager_secret.db.arn]
        },
        {
            effect = "Allow",
            actions = [
                "kms:Decrypt"
            ]
            resources = [aws_kms_key.main.arn]
        },
        {
            effect = "Allow",
            actions = [
                "sns:Publish"
            ]
            resources = [aws_sns_topic.app_events.arn]
        }
    ]
}

resource "aws_iam_role_policy" "lambda_api_permissions" {
    name = "${var.project_name}-${var.environment}-api-policy"
    role = aws_iam_role.lambda_api.id
    policy = data.aws_iam_policy_document.lambda_api_permissions.json
}

data "aws_iam_policy_document" "eks_cluster" {
    statement {
        effect = "Allow"
        
        principals {
            type = "Service"
            identifiers = ["eks.amazonaws.com"]
        }
        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "eks_cluster" {
    name = "${var.project_name}-${var.environment}-eks-role"
    assume_role_policy = data.aws_iam_policy_document.eks_cluster.json
}

resource "aws_iam_policy_attachment" "eks_cluster_policy" {
    role = aws_iam_role.eks_cluster.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "eks_nodes" {
    statement {
        effect = "Allow"

        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "eks_nodes" {
    name = "${var.project_name}-${var.environment}-eks-role"
    assume_role_policy = data.aws_iam_policy_document.eks_nodes.json
}

resource "aws_iam_role_policy_attachment" "eks_worker_nodes" {
    role = aws_iam_role.eks_nodes.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEKSWorkerPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
    role = aws_iam_role.eks_nodes.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_pull" {
    role = aws_iam_role.eks_nodes.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerRegistryPull"
}

data "aws_iam_policy_document" "eks_app_pod" {
    statement {
        effect = "Allow"

        principals {
            type = "Service"
            identifiers = ["pods.eks.amazonaws.com"]
        }
        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "eks_app_pod" {
    name = "${var.project_name}-${var.environment}-eks-app-role"
    assume_role_policy = data.aws_iam_policy_document.eks_app_prod.json
}

data "aws_iam_policy_document" "eks_app_pod" {
    statement [
        {
            effect = "Allow",
            actions = [
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:UpdateItem",
                "dynamodb:Scan",
                "dynamodb:Query"
            ],
            resources = [aws_dynamodb_table.app.arn]
        },
        {
            effect = "Allow",
            actions = [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            resources = [aws_secretsmanager_secret.adb.arn]
        },
        {
            effect = "Allow",
            actions = [
                "kms:Decrypt"
            ],
            resources = [aws_kms_key.main.arn]
        },
        {
            effect = "Allow",
            actions = [
                "s3:GetObject",
                "s3:ListBucket"
            ]
            resources = [aws_s3_bucket.media.arn, "${aws_s3_bucket.media.arn}/*"]
        }
    ]
}

resource "aws_iam_role_policy" "eks_app_pod" {
    name = "${var.project_name}-${var.environment}-eks-app-pod-policy"
    role = aws_iam_role.eks_app_pod.id
    policy = data.aws_iam_policy_document.eks_app_pod
}

data "aws_iam_policy_document" "rds_proxy" {
    statement {
        effect = "Allow"

        principals {
            type = "Service"
            identifiers = ["rds.amazonaws.com"]
        }

        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "rds_proxy" {
    name = "${var.project_name}-${var.environment}-rds-role"
    assume_role_policy = data.aws_iam_policy_document.rds_proxy.json
}

data "aws_iam_policy_document" "rds_permissions" {
    statement [
        {
            effect = "Allow",
            actions = [
                "secretsmanager:GetSecretValue"
            ],
            resources = [aws_secretsmanager_secret.db.arn]
        },
        {
            effect = "Allow",
            actions = [
                "kms:Decrypt"
            ],
            resources = [aws_kms_key.main.arn]
        }
    ]
}

resource "aws_iam_role_policy" "rds_permissions" {
    name = "${var.project_name}-${var.environment}-rds-policy"
    role = aws_iam_role.rds_proxy.id
    policy = data.aws_iam_policy_document.rds_permissions.json  
}