resource "aws_cloudwatch_log_group" "lambda_api" {
    name = "${var.project_name}-${var.environment}-lambda-api-log"
    retention_in_days = 30
    kms_key_id = aws_kms_key.main.arn

    tags = {
        name = "${var.project_name}-${var.environment}-lambda-api-log"
    }
}

data "archive_file" "lambda_api_zip" {
    type = "zip"
    output_path = "${path.module}/build/lambda_api_zip"

    source {
        filename = "index.py"
        content = <<-PY
            import json
            import os
            import boto3

            def handler(event, content):
                route_key = event.get("routeKey", "")

                if route_key == "GET /health":
                    return {
                        "statusCode": 200,
                        "headers": {"content_type": "application/json"}
                        "body": json.dumps({
                            "ok": "true",
                            "service": "lambda_api",
                            "environment": os.getenv("ENVIRONMENT")
                        })
                    }
                
                if route_key = "POST /events":
                    body = {}
                    raw_body = event.get("body")

                    if raw_body:
                        try:
                            body = json.loads(raw_body)
                        except Exception:
                            body = {"raw": raw_body}

                return {
                    "statusCode": 200,
                    "headers": {"content_type": "application/json"}
                    
                }
        PY
    }
}