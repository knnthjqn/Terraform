data "aws_iam_policy_document" "ecs_task_assume_role" {
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
  name = "${var.project_name}-${var.environment}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
}

resource "aws_iam_role" "ecs_web" {
  name = "${var.project_name}-${var.environment}-ecs-web-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role" "ecs_app" {
  name = "${var.project_name}-${var.environment}-ecs-app-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy_document" "ecs_app_permission" {
  statement {
    sid = "DynamoReadWrite
    effect = "Allow"
    actions = [
      "dynamodb: BatchGetItem"
      "dynamodb: BatchWriteItem"
      "dynamodb: PutItem"
      "dynamodb: GetItem"
      "dynamodb: UpdateItem"
      "dynamodb: DeleteItem"
      "dynamodb: DescribeTable"
      "dynamodb: Query
    ]
    resource = aws_dynamodb_table.app.arn
  }

  statement {
    sid = "ReadDBSecret"
    effect = "Allow"
    actions = [
      "secretsmanager: GetSecretValue"
      "secretsmanager: DescribeSecret"
    ]
    resource = aws_secretsmanager_secret.db.arn
  }

  statement {
    sid = "ReadMediaObject"
    effect = "Allow"
    actions = [
      "s3: GetObject"
    ]
    resource = "${aws_s3_bucket.media.arn}/*"
  }

  statement {
    sid = "ListMediaBucket" 
    effect = "Allow"
    actions = [
      "s3: ListBucket"
    ]
    resource = aws_s3_bucket.media.arn
  }
}

resource "aws_iam_role_policy" "ecs_app_permission" {
  name = "${var.project_name}-${var.environment}-ecs-app-permission"
  role = aws_iam_role.ecs_app.id
  policy = data.aws_iam_policy_document.ecs_app_permission.json
}

resource "aws_iam_role" "rds_proxy" {
  name = "${var.project_name}-${var.environment}-rds-proxy"

  assume_role_policy = jsonencode ({
    Statement = [{
      effect = "Allow"
      principal = {
        Service = "rds.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "rds_proxy" {
  name = "${var.project_name}-${var.environment}-rds-proxy-policy"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode ({
    Statement = [{
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue"
      ]
      resource = aws_secretsmanager_secret.db.arn
    },
      effect = "Allow"
      actions = [
        "kms:Decrypt"
      ]
      resource = aws_kms_key.main.arn
    ]
  })
}