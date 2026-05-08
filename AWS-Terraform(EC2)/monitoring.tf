resource "aws_sns_topic" "main" {
    name = "${var.project_name}-${var.environment}-sns-topic"
    kms_key_id = aws_kms_key.main.id
}

resource "aws_sns_topic_subscription" "main" {
    name = "${var.project_name}-${var.environment}-sns-subscription"
    protocol = "email"
    endpoint = var.alerts_email
}

resource "aws_cloudwatch_metric_alarm" "web_high_cpu" {
    name = "${var.project_name}-${var.environment}-web-alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 1
    metric_name = "AWS/EC2"
    namespace = "Web High CPU Usage"
    period = 30
    statistic = "Average"
    threshold = 80

    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.web.name
    }

    alarm_actions = [aws_sns_topic.main.arn]
    ok_actions = [aws_sns_topic.main.arn]
}

resource "aws_cloudwatch_metric_alarm" "app_high_cpu" {
    name = "${var.project_name}-${var.environment}-app-alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 1
    metric_name = "AWS/EC2"
    namespace = "App High CPU Usage"
    period = 30
    statistic = "Average"
    threshold = 80

    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.app.name
    }

    alarm_actions = [aws_sns_topic.main.arn]
    ok_actions = [aws_sns_topic.main.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
    name = "${var.project_name}-${var.environment}-rds-alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 1
    metric_name = "AWS/RDS"
    namespace = "RDS High CPU Usage"
    period = 30
    statistic = "Average"
    threshold = 80

    dimensions = {
        DBInstanceIdentifier = aws_db_instance.main.identifier
    }

    alarm_actions = [aws_sns_topic.main.arn]
    ok_actions = [aws_sns_topic.main.arn]
}
