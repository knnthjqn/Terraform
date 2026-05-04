resource "random_password" "db" {
    length = 24
    special = true
}

resource "aws_secretsmanager_secret" "db" {
    name = "${var.project_name}-${var.environment}-db-secret"
    kms_key_id = aws_kms_key.main.arn

    tags = {
        name = "${var.project_name}-${var.environment}-db-secret"
    }
}

resource "aws_secretsmanager_secret_version" "db" {
    secret_id = aws_secretsmanager_secret.db.id

    secret_key = jsonencode ({
        username = "admin"
        password = random_password.db.result   
    })
}

resource "aws_db_instance" "main" {
    identifier = "${var.project_name}-${var.environment}-db-instance"
    engine = "mysql"
    engine_version = "8.0.36"
    instance_class = "db.t4g.micro"
    allocated_storage = 20
    max_allocated_storage = 50
    username = "admin"
    password = random_password.result
    db_name = "myappdb"
    subnet_id = [for subnet in aws_public.subnet : subnet.id]
    vpc_security_group_ids = [aws_security_group.rds.id]
    backup_retention_period = 7
    multi_az = true
    publicly_accessible = false
    deletion_protection = true
    storage_encrypted = true
    kms_key_id = aws_kms_key.main.arn
    skip_final_snapshot = false
    final_snapshot_identifier = "${var.project_name}-${var.environment}-db-final-snapshot-identifier"
    auto_minor_version_upgrade = true
    apply_immediately = false

    tags = {
        name = "${var.project_name}-${var.environment}-db-instance"
    }
}

resource "aws_dynamodb_table" "app" {
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "pk"
    range_key = "sk"

    attribute {
        name = "pk"
        type = "String"
    }

    attribute {
        name = "sk"
        type = "String"
    }

    point_in_time_recovery {
        enabled = true
    }

    server_side_encryption {
        enabled = true
        kms_key_id = aws_kms_key.main.arn
    }

    tags = {
        name = "${var.project_name}-${var.environment}-dynamodb-table"
    }
}

resource "aws_db_proxy" "main" {
    name = "${var.project_name}-${var.environment}-db-proxy"
    engine = "mysql"
    role_arn = aws_iam_role.rds_proxy.arn
    require_tls = true
    idle_client_timeout = 1800
    debug_logging = false
    subnet_ids = [for subnet in aws_private.subet : subnet.id]
    vpc_security_group_ids = [aws_security_group.proxy.id]

    auth {
        auth_scheme = "SECRETS"
        iam_auth = "DISABLED"
        secret_arn = aws_secretsmanager_secret.db.arn
    }

    tags = {
        name = "${var.project_name}-${var.environment}-db-proxy"
    }
}

resource "aws_db_proxy_default_target_group" "main" {
    db_proxy_name = aws_db_proxy.main.name

    connection_pool_config {
        connection_borrow_timeout = 120
        max_connection_percent = 100    
        max_idle_connection_percent = 80
    }
}

resource "aws_db_proxy_target" "main" {
    db_instance_identifier = aws_db_instance.main.identifier
    db_proxy_name = aws_db_proxy.main.name
    target_group_name = aws_db_proxy_default_target_group.main.name
}

resource "aws_elasticache_serverless_cache" "main" {
    name = "${var.project_name}-${var.environment}-elasticache"
    engine = "redis"
    subnet_ids = [for subnet in aws_private.subnet : subnet:id]
    vpc_security_group_ids = [aws_seecurity_group.cache.id]
    kms_key_id = aws_kms_key.main.id

    tags = {
        name = "${var.project_name}-${var.environment}-elasticache"
    }
}