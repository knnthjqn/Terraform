resource "aws_sns_topic" "main" {
    name = "${var.project_name}-${var.environment}-sns-topic"
    kms_key_id = aws_kms_key.main.id
}

resource "aws_sns_topic_subscription" "main" {
    topic_arn = aws_sns_topic.main.arn
    protocol = "email"
    endpoint = var.alerts_email
}

resource "aws_cloudwatch_metric_alarm" "web_high_cpu" {
    alamr_name = "${var.project_name}-${var.environment}-web-alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 2
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = 60
    statistic = "Average"
    threshold = 80

    dimensions {
        AutoScalingGroupName = aws_autoscaling_group.web.name
    }

    alarm_actions = [aws_sns_topic.main.arn]
    ok_actions = [aws_sns_topic.main.arn]
}

resource "aws_cloudwatch_metric_alarm" "app_high_cpu" {
    alarm_name = "${var.project_name}-${var.environment}-app-alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 2
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = 60
    statistic = "Average"
    threshold = 80

    dimensions {
        AutoScalingGroupName = aws_autoscaling_group.app.name
    }

    alarm_actions = [aws_sns_topic.main.arn]
    ok_actions = [aws_sns_topic.main.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
    alarm_name = "${var.project_name}-${var.environment}-rds-alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 2
    metric_name = "CPUUtilization"
    namespace = "AWS/RDS"
    period = 60
    statistic = "Average"
    threshold = 80

    dimensions {
        DBInstanceIdentifier = aws_db_instance.main.identifier
    }

    alarm_actions = [aws_sns_topic.main.arn]
    ok_actions = [aws_sns_topic.main.arn]
}

