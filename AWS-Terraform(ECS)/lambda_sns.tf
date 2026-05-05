resource "aws_cloudwatch_log_group" "lambda_sns" {
    name = "${var.project_name}-${var.environment}-sns-logs"
    retention_in_days = 30
    kms_key_id = aws_kms_key.main.arn

    tags = {
        Name = "${var.project_name}-${var.environment}-sns-logs"
    }
}

data "archive_file" "lambda_sns_zip" {
    type = "zip"
    path_module = "${path.module}/build/lambda_sns.zip"

    source {
        content = <<-PY
        import json
        import os
        import boto3

        ddb = boto3.client("dynamodb")

        def handler(event, context):
            for record in events.get("Records", []):
                message = records.get("Sns", {}).get("Message", "{}")

                try:
                    parsed = json.loads(message)
                except Exception:
                    parsed = {"raw": message}

                ddb.putItem(
                    TableName = os.getenv("DDB_TABLE"),
                    Item = {
                        "pk" : {"S": "EVENT"},
                        "sk" : {"S": context.aws_request_id},
                        "payload" : {"S": json.dumps(parsed)}
                    }
                )
            
            return {"ok": True}
        PY
        filename = "index.py"
    }
}

resource "aws_sns_topic" "app_events" {
    name = "${var.project_name}-${var.environment}-app-events"
    kms_key_id = aws_kms_key.main.arn

    tags = {
        Name = "${var.project_name}-${var.environment}-app-events"
    }
}

resource "aws_lambda_function" "sns_handler" {
    function_name = "${var.project_name}-${var.environment}-sns-handler"
    role = aws_iam_role.lambda_sns.arn
    runtime = var.lambda_runtime
    handler = "index.handler"
    timeout = var.lambda_timeout_seconds
    memory_size = var.lambda_memory_mb
    kms_key_arn = aws_kms_key.main.arn

    filename = data.archive_file.lambda_sns_zip.output_path
    source_code_hash = data.archive_file.lambda_sns_zip.output_based64sha256

    vpc_config {
        subnets = [for subnet in subnet.private : subnet.id]
        sucurity_group_ids = [aws_security_group.lambda.id]
    }

    environment { 
        variable = {
            DDB_TABLE = aws_dynamodb_table.main.name
            ENVIRONMENT = var.environment
        }
    }

    depends_on = [aws_cloudwatch_log_group.lambda_sns]

    tags = {
        Name = "${var.project_name}-${var.environment}-sns-handler"
    }
}

resource "aws_sns_topic_subscription" "app_events" {
    topic_arn = aws_sns_topic.app.events.arn
    protocol = "lambda"
    endpoint =  aws_lambda_function.sns_handler.arn
}
