resource "aws_iam_role" "web" {
    name = "${var.project_name}-${var.environment}-web-role"

    assume_role_policy = jsonencode({
        Statement = [{
            Effect = "Allow",
            Resource = "ec2.amazonaws.com",
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_instance_profile" {
    name = "${var.project_name}-${var.environment}-web-profile"
    role = aws_iam_role.web.name
}

resource "aws_iam_role_policy_attachment" "web" {
    role = aws_iam_role.web.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMManagedInstanceCore"    
}

resource "aws_iam_role" "app" {
    name = "${var.project_name}-${var.environment}-app-role"

    assume_role_policy = jsonencode({
        Statement = [{
            Effect = "Allow",
            Resource = "ec2.amazonaws.com",
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_instance_profile" "app" {
    name = "${var.project_name}-${var.environment}-app-profile"
    role = aws_iam_role.app.name
}

resource "aws_iam_role_policy_attachment" "app" {
    role = aws_iam_role.app.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "app" {
    name = "${var.project_name}-${var.environment}-app-inline"
    role = aws_iam_role.app.name

    policy = jsonencode({
        Statement = [
            {
                Effect = "Allow",
                Actions = [
                    "dynamodb:GetItem",
                    "dynamodb:PutItem",
                    "dynamodb:DeleteItem",
                    "dynamodb:UpdateItem",
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
                Resources = [
                    aws_s3_bucket.media.arn,
                    "${aws_s3_bucket.media.arn}/*"
                ]
            }
        ]
    })
}


resource "aws_iam_role" "rds_proxy" {
    name = "${var.project_name}-${var.environment}-rds-assume-role"

    assume_role_policy = jsonencode({
        Statement = [{
            Effect = "Allow",
            Resource = {
                Service = "rds.amazonaws.com",
            },
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy" "rds_proxy" {
    name = "${var.project_name}-${var.environment}-rds-role-policy"
    role = aws_iam_role.app.name

    policy = jsonencode({
        Statement = [
            {
                Effect = "Allow",
                Action = "sceretsmanager:GetSecretValue",
                Resource = aws_secretsmanager_secret.db.arn
            },
            {
                Effect = "Allow",
                Action = "kmsDecrypt",
                Resource = aws_kms_key.main.arn
            }
        ]
    })
}