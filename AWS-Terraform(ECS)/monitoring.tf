resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-sns-topic"
  kms_master_key_id = aws_kms_key.main.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-sns-topic"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol = "email"
  endpoint = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name = "${var.project_name}-${var.environment}-unhealthy-host-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = "UnhealthyHostCount"
  namespace = "AWS/ApplicationELB"
  period = 60
  statistic = "Average"
  threshold = 1
  alarm_description = "ALB has unhealthy hosts"

  dimensions = {
    TargetGroup = aws_lb_target_group.ecs_web.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_web_high_cpu" {
  alarm_name = "${var.project_name}-${var.environment}-ecs-web-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = "ECSWebHighCPU"
  namespace "AWS/ECS"
  period = 60
  statistic = "Average"
  threshold = 1
  alarm_description = "Web ECS high cpu usage"

  dimensions { 
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.web.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_app_high_cpu" {
  Name = "${var.project_name}-${var.environment}-ecs-app-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 1
  metric_name = "ECSAppHighCPU"
  namespace = "AWS/ECS"
  period = 60
  statistic = " Average"
  threshold = 1
  alarm_description = "App ECS high cpu usage"

  dimensions { 
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "db_high_cpu" {
    alarm_name = "${var.project_name}-${var.environment}-db-high-cpu"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 1
    metric_name = "DbHighCPU"
    namespace = "AWS/RDS"
    period = 60
    statistic = "Average"
    threshold = 1
    alarm_description = "Db high cpu usage"

    dimensions = {
      DBInstanceIdentifier = aws_db_instance.main.id
    }

    alarm_actions = [aws_sns_topic.alerts.arn]
    ok_actions = [aws_sns_topic.alerts.arn]
}