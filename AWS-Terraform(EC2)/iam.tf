resource "aws_iam_role" "web" {
    name = "${var.project_name}-web-role"

    assume_role__policy = jsonencode({
        Statement = [{
            Effect = "Allow",
            Resources = ["ec2.amazonaws.com"],
            Actions = ["sts:AssumeRole"]
        }]
    })
}

resource "aws_iam_instance_profile" "web" {
    name = "${var.project_name}-web-profile"
    role = aws_iam_role.web.name
}

resource "aws_iam_role" "app" {
    name = "${var.project_name}-app-role"

    assume_role_policy = jsonencode ({
        Statement = [{
            Effect = "Allow",
            Resources = ["ec2.amazonaws.com"],
            Actions = ["sts:AssumeRole"]
        }]
    })
}

resource "aws_iam_instance_profile" "app" {
    name = "${var.project_name}-app-profile"
    role = aws_iam_role.app.name
}

resource "aws_iam_role_policy" "app" {
    name = "${var.project_name}-app-role-policy"
    role = aws_iam_role.app.id

    policy = jsonencode({
        Statement [
            {
                Effect = "Allow",
                Actions = [
                    "dynamodb:GetItem",
                    "dynamodb:PutItem",
                    "dynamodb:DeleteItem",
                    "dynamodb:UpdateItem",
                    "dynamodb:Query",
                    "dynamodb:Scan",
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
    name = "${var.project_name}-rds-role"

    assume_role_policy = jsonencode({
        Statement = [{
            Effect = "Allow",
            Resources = ["rds.amazonaws.com"],
            Actions = ["sts:AssumeRole"]
        }]
    })
}

resource "aws_iam_role_policy" "rds_proxy" {
    name = "${var.project_name}-web-role-policy"
    role = aws_iam_role.rds_proxy.id

    policy = jsonencode({
        Statement = [
            {
                Effect = "Allow",
                Actions = [
                    "secretsmanager:GetSecretValue"
                ],
                Resources = [aws_secretsmanager_secret.db.arn]
            },
            {
                Effect = "Allow",
                Actions = [
                    "kms:Decrypt"
                ],
                Resources = [aws_kms_key.main.arn]
            }
        ]
    })
}