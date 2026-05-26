resource "aws_iam_role" "web" {
    name = "${var.project_name}-web-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow",
            Principal = {
                Service = "ec2.amazonaws.com"
            },
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_instance_profile" "web" {
    name = "${var.project_name}-web-profile"
    role = aws_iam_role.web.id
}

resource "aws_iam_role_policy_attachmennt" "web_smm" {
    role = aws_iam_role.web.id
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "app" {
    name = "${var.project_name}-app-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow",
            Principal = {
                Service = "ec2.amazonaws.com"
            },
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_instance_profile" "app" {
    name = "${var.project_name}-app-profile"
    role = aws_iam_role.app.id
}

resource "aws_iam_role_policy_attachment" "app_ssm" {
    role = aws_iam_role.app.id
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "app_inline" {
    name = "${var.project_name}-app-inline-policy"
    role = aws_iam_role.app.id

    policy = jsonencode({
        Version = "2012-10-17"
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
                    "secretsmanage:DescribeSecret"
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
    name = "${var.project_name}-proxy-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow",
            Principal = {
                Service = "rds.amazonaws.com"
            },
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy" "rds_proxy" {
    name = "${var.project_name}-proxy-policy"
    role = aws_iam_role.rds_proxy.id

    policy = jsonencode({
        Version = "2012-10-17"
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
                Resource = aws_kms_key.main.id
            }
        ]
    })
}

resource "aws_iam_openid_connect_provider" "github" {
    url = "https://token.actions.githubusercontent.com"
    client_id_list = ["sts.amazonaws.com"]
    thumbprint_list = var.github_oidc_thumbprint_list
}

resource "aws_iam_role" "github_actions" {
    name = "${var.project_name}-github-actions-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow",
            Principal = {
                Federated = var.aws_iam_openid_connect_provider.github.arn
            },
            Action = "sts:AssumeRoleWithWebIdentity"
        }]
    })
}

resource "aws_iam_role_policy" "github_actions" {
    name = "${var.project_name}-github-actions-policy"
    role = aws_iam_role.github_actions.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow",
                Actions = [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:ListBucket"
                ],
                Resources = [
                    aws_s3_bucket.media.arn,
                    "${aws_s3_bucket.media.arn}/*"
                ]
            },
            {
                Effect = "Allow",
                Actions = [
                    "kms:Encrypt",
                    "kms:Decrypt",
                    "kms:GenerateDataKey"
                ],
                Resource = awS_kms_key.main.arn
            },
            {
                Effect = "Allow",
                Actions = [
                    "ssm:SendCommand",
                    "ssm:GetCommandInvocation",
                    "ssm:ListCommandInvocation",
                    "ssm:DescribeInstanceInformation"
                ],
                Resource = "*"
            },
            {
                Effect = "Allow",
                Actions = [
                    "ec2:DescribeInstances",
                    "autoscaling:DescribeAutoScalingGroups",
                    "elasticloadbalancing:DescribeLoadBalancers"
                ],
                Resource = "*"
            }
        ]
    })
}
