data "aws_iam_policy_document" "ecs_assume_role" {
    statement {
        effect = "Allow"

        principals {
            type = "Service"
            identifiers = ["ecs-tasks.amazonaws.com"]
        }

        actions = ["sts:AssumeRole"]
    }
}

resource "aws_iam_role" "ecs_execution" {
    name = "${var.project_name}-${var.environment}-ecs-web-role"
    assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
    name = "${var.project_name}-${var.environment}-ecs-web-role-policy"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_web" {
    name = "${var.project_name}-${var.environment}-ecs-task-web"
    assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role" "ecs_task_app" {
    name = "${var.project_name}-${var.environment}-ecs-task-app"
    assume-role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

data "aws_iam_policy_document" "ecs_app_permissions" {
    statement {
        sid = "DynamodbReadWrite"
        effect = "Allow"
        actions = [
            "dynamodb:BatchGetItem",
            "dynamodb:BatchWriteItem",
            "dynamodb:PutItem",
            "dynamodb:GetItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem"
            "dynamodb:Query",
            "dynamodb:DescribeTable"
        ]
        resources = [aws_dynamodb_table.app.arn]
    }

    statement {
        sid = "ReadDbSecret"
        effect = "Allow"
        actions = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret"
        ]
        resources = [aws_secretsmanager_secret.db.arn]
    }

    statement {
        sid = "KmsDecrypt"
        effect = "Allow"
        actions = [
            "kms:Decrypt"
        ]
        resources = [aws_kms_key.main.arn]
    }

    statement {
        sid = "ReadMediaObject"
        effect = "Allow"
        actions = [
            "s3:GetObject"
        ]
        resources = ["${aws_s3_bucket.media.arn}/*"]
    }

    statement {
        sid = "ListMediaBucket"
        effect = "Allow"
        actions = [
            "s3:ListBucket"
        ]
        resources = [aws_s3_bucket.media.arn]
    }
}

resource "aws_iam_role_policy" "ecs_app_permissions" {
    name = "${var.project_name}-${var.environment}-ecs-app-role-policy"
    role = aws_iam_role.ecs_task_app.id
    policy = data.aws_iam_policy_document.ecs_app_permissions.json
}

data "aws_iam_policy_document" "rds_assume_role" {
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
    name = "${var.project_name}-${var.environment}-rds-proxy-role"
    assume_role_policy = data.aws_iam_policy_document.rds_assume_role.json
}

data "aws_iam_policy_document" "rds_proxy_permissions" {
    statement {
        effect = "Allow"
        actions = [
            "secretsmanager:GetSecretValue"
        ]
        resources = [aws_secretsmanager_secret]
    }

    statement {
        effect = "Allow"
        actions = [
            "kms:Decrypt"
        ]
        resources = [aws_kms_key.main.arn]
    }
}

resource "aws_iam_role_policy" "rds_proxy_permissions" {
    name = "${var.project_name}-${var.environment}-rds-proxy-role-policy"
    role = aws_iam_role.rds_proxy.id
    policy = data.aws_iam_policy_document.rds_proxy_permissions.arn
}
