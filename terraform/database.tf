resource "random_password" "db" {
    length = 24
    special = true
}

resource "aws_secretsmanager_secret" "db" {
    name = "${var.project_name}-${var.environment}-secret"
    kms_key_id = aws_kms_key.main.arn
}

resource "aws_secretsmanager_secret_version" "db" {
    secret_id = aws_secretsmanager_secret.db.arn

    secret_key = jsonencode ({
        username = "admin"
        password = random_password.db.result
    })
}

resource "aws_dynamodb_table" "app" {
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "pk"
    range_key = "sk"

    attribute {
        name = "pk"
        type = "S"
    }

    attribute {
        name = "sk"
        type = "S"
    }

    point_in_time_recovery {
        enabled = true
    }

    server_side_encryption {
        enabled = true
        kms_key_id = aws_kms_key.main.arn
    }
}

resource "aws_db_instance" "