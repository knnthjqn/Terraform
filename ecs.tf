resource "aws_cloudwatch_log_group" "web" {
  name = "${var.project_name}-${var.environment}-web-logs"
  retention_in_days = 30
  kms_key_id = aws_kms_key.main.arn
}

resource "aws_cloudwatch_log_group" "app" {
  name = "${var.project_name}-${var.environment}-app-logs"
  retention_in_days = 30
  kms_key_id = aws_kms_key.main.arn
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-ecs-cluster"

  settings {
    name = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-cluster"
  }
}

resource "aws_lb_target_group" "ecs_web" {
  name = "${var.project_name}-${var.environment}-web-tg"
  port = 8080
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = vpc.main.id

  health_check = {
    enabled = true
    path = "/"
    matcher = "200-399"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-web-tg"
  }
}

resource "aws_ecs_task_definition" "ecs_web" {
  family = "${var.project_name}-${var.environment}-ecs-task"
  network_mode = "awsvpc"
  requires_compatibilies = ["FARGATE"]
  cpu = 512
  memory = 1024
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task.arn
  
  container_definitions = [(
    {
      name = "web"
      image = "nginx:stable"
      essential = True
      portMappings = [{
        containerPort = 8080
        hostPort = 8080
        protocol = "tcp"
      }]

      command = [
        "/bin/sh",
        "-c"
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.web.name
          awslogs-region = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  )]

  tags = {
    Name = "${var.project_name}-${var.environment}-web-task"
  }
}

reource "aws_ecs_task_definition" "ecs_app" {
  name = "${var.project_name}-${var.environment}-app-task"
  network_mode = "awsvpc"
  requires_compatibilies = ["FARGATE"]
  cpu = 512
  memory = 1024
  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn = aws_iam_role.ecs_task.arn

  container_definitions = [(
    {
      name = "app"
      image = "public.ecr.aws/docker/library/python:3.11-slim"
      essential = true
      portMappings = [
        containerPort = 9000
        hostPort = 9000
        protocol = "tcp"
      ]

      command = [
        "python",
        "-m",
        "http.server"
        "9000"
      ]

      environment = [
        { name = "DB_PROXY_HOST", value = aws_db_proxy.main.endpoint },
        { name = "DB_PORT", value = "3306" },
        { name = "DB_NAME", value = var.db_name }
        { name = "DDB_TABLE", value = aws_dynamodb_table.main.name },
        { name = "CACHE_HOST" value = aws_elasticache_serverless_cache.main.endpoint[0].address },
        { name = "CACHE_PORT", value = "6379" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.app.name
          awslogs-region = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  )]

  tags = {
    Name = "${var.project_name}-${var.environment}-app-task"
  }
}

resource "aws_ecs_service" "web" [
  name = "${var.project_name}-${var.environment}-web-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ecs_web.arn
  desired_count = 2
  launch_type = "FARGATE"

  deployment_minimum_health_percent = 50
  deployment_maximum_percent = 200

  network_configuration {
    subnets = [for subnet in private.subnet : subnet:id]
    security_group_ids = [aws_security_group.ecs_web.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_web.arn
    container_name = "web"
    container_port = "8080"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-service"
  }
]

resource "aws_ecs_service" "app" {
  name = "${var.project_name}-${var.environment}-app-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ecs_app.arn
  desired_count = 2
  launch_type = "FARGATE"

  deployment_minimum_health_percent = 50
  deployment_maximum_percent = 200

  network_configuration {
    subnets = [for subnet in private.subnet : subnet.id]
    security_group_ids = [aws_security_group.ecs_app.id]
    assign_public_ip = false
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-service"
  }
}

resource "aws_autoscaling_target" "web" {
  min_capacity = 2
  max_capacity = 4
  resource_id = "/service/${var.project_name}/${var.environment}/web-tg"
  scalable_dimension = "service:ecs:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_autoscaling_policy" "web_cpu" {
  name = "${var.project_name}-${var.environment}-web-asg"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_autoscaling_policy.web.resource_id
  scalable_dimension = aws_autoscaling_policy.web.scalable_dimension
  service_namespace = aws_autoscaling_policy.web.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtiliztion"
    }

    target_value = 50
  }
}

resource "aws_autoscaling_target" "app" {
  min_capacity = 2
  max_capacity = 4
  resource_id = /service/${var.project_name}/${var.environment}/app-tg"
  scalable_dimension = "service:aws:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_autoscaling_policy" "app_cpu" {
  name = "${var.project_name}-${var.environment}-app-asg"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_autoscaling_target.app.resource_id
  scalable_dimension = aws_autoscaling_target.app.scalable_dimension
  service_namespace = aws_autoscaling_target.app.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 50
  }
}