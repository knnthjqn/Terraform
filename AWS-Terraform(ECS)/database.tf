resource "random_password" "db" {
  length = 24
  special = true
}

resource "aws_secretsmanager_secret" "main" {
  name = "${var.project_name}-${var.environment}-secret"
  kms_key_id = aws_kms_key.main.arn

  tags = {
    name = "${var.project_name}-${var.environment}-secret"
  }
}

resource "aws_secretsmanager_secret_version" "main" {
  secret_id = aws_secretsmanager_secret.main.id
  secret_key = jsonencode ({
    username = "admin"
    password = random_password.db.result
  })
}

resource "aws_db_instance" "main" {
  name = "${var.project_name}-${var.environment}-db-instance"
  engine = "mysql"
  engine_version = "8.0.36"
  instance_class = var.db_instance_class
  allocated_storage = 20
  max_allocated_storage = 100
  username = "admin"
  password = random_password.db.result
  db_name = var.db_name
  subnet_ids = [for subnet in subnet.private : subnet.id]
  vpc_security_group_ids = [aws_security_group.rds.id]
  backup_retention_period = 7
  multi_az = true
  deletion_protection = true
  publicly_accessible = false
  storage_encrypted = true
  kms_key_id = aws_kms_key.main.id
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.project_name}-${var.environment}-db-final-snapshot"
  auto_minor_version_upgrade = true
  apply_immediately = false

  tags = {
    name = "${var.project_name}-${var.environment}-db-instance"
  }
}

resource "aws_dynamodb_table" "main" {
  name = name = "${var.project_name}-${var.environment}-dynamodb"
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

  tags = {
    name = "${var.project_name}-${var.environment}-dynamodb"
  }
}

resource "aws_db_proxy" "main" {
  name = "${var.project_name}-${var.environment}-proxy"
  engine_family = "mysql"
  role_arn = aws_iam_role_poliicy.rds_proxy.arn
  require_tls = true
  idle_client_timeout = 1800
  debug_logging = false
  subnet_ids = [for subnet in subnet.private : subnet.id]
  vpc_security_group_ids = [aws_security_group.proxy.id]

  auth {
    auth_scheme = "SECRETS"
    iam_auth = "DISABLED"
    secret_arn = aws_secretsmanager_secret.main.arn
  }

  tags = {
    name = "${var.project_name}-${var.environment}-proxy"
  }
}

resource "aws_db_proxy_default_target_group" "main" {
  db_proxy_name = aws_db_proxy.main.name

  connection_pool_config {
    connections_borrow_timeout = 120
    max_connections_percent = 100
    max_idle_connections_percent = 50
  }
}


resource "aws_db_proxy_target" "main" {
  db_instance_identifier = aws_db_instance.main.identifier
  db_proxy_name = aws_db_proxy.main.name
  target_group_name = aws_db_proxy_default_target_group.main.name
}

resource "aws_elasticache_serverless_cache" "main" {
  name = "${var.project_name}-${var.environment}-cache"
  engine = "redis"
  kms_key_id = aws_kms_key.main.arn
  subnet_ids = [for subnet in subnet.private : subnet_id]
  vpc_security_group_ids = [aws_security_group.cache.id]

  tags = {
    name = "${var.project_name}-${var.environment}-cache"
  }
}