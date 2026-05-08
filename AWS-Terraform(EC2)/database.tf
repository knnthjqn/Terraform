resource "random_password" "db" {
    length = 24
    special = true
}

resource "aws_secretsmanager_secret" "db" {
    name = "${var.project_name}-${var.environment}-secretsmanager"
    kms_key_id = aws_kms_key.main.arn
}

resource "aws_secretsmanager_secret_version" "db" {
    secret_id = aws_secretsmanager_secret.db.id

    secret_string = jsonencode({
        username = "admin"
        password = random_password.db.result
    })
}

resource "aws_dynamodb_table" "app" {
    name = "${var.project_name}-${var.environment}-dynamdb"
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
        kms_key_arn = aws_kms_key.main.arn
    }
}

resource "aws_db_instance" "main" {
    identifier = "${var.project_name}-${var.environment}-db"
    engine = "mysql"
    engine_version = "8.0"
    instance_class = var.db_instance_class
    allocated_storage = 50
    max_allocated_storage = 100
    username = "admin"
    password = random_password.db.result
    db_name = var.db_name
    subnet_ids = [for subnet in aws_subnet.private : subnet.id]
    vpc_security_group_id = [aws_security_group.rds.id]
    storage_encrypted = true
    kms_key_id = aws_kms_key.main.arn
    backup_retention_period = 7
    multi_az = true
    public_accessible = false
    deletion_protection = true
    skip_final_snapshot = false
    final_snapshot_identifier = "${var.project_name}-${var.environment}-db-final-snapshot"
    apply_minor_version_upgrade = true
    apply_immediately = false
}

resource "aws_db_proxy" "main" {
    engine_family = "mysql"
    role = aws_iam_role.rds_proxy.id
    require_tls = true
    idle_client_timeout = 1800
    subnet_ids = [for subnet in aws_subnet.private : subnet.id]
    vpc_security_group_ids = [aws_security_group.proxy.id]

    auth {
        auth_scheme = "SECRETS"
        iam_auth = "DISABLED"
        secret_arn = aws_secretsmanager_secret.db.arn
    }
}

resource "aws_db_proxy_default_target_group" "main" {
    db_proxy_name = aws_db_proxy.main.name
}

resource "aws_db_proxy_target" "main" {
    db_instance_identifer = aws_db_instance.main.identifier
    db_proxy_name = aws_db_proxy.main.name
    target_group_name = aws_db_proxy_default_target_group.main.name
}

resource "aws_elasticache_serverless_cache" "main" {
    name = "${var.project_name}-${var.environment}-cache"
    engine = "redis"
    subnet_id = [for subnet in aws_subnet.private : subnet.id]
    security_group_ids = [aws_security_group.cache.id]
    kms_key_id = aws_kms_key.main.arn
}