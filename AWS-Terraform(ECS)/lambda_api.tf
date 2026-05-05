resource "aws_cloudwatch_log_group" "lambda_api" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-api-handler"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.main.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-api-handler-logs"
  }
}

data "archive_file" "lambda_api_zip" {
  type        = "zip"
  output_path = "${path.module}/build/lambda_api.zip"

  source {
    content  = <<-PY
      import json
      import os
      import boto3

      sns = boto3.client("sns")

      def handler(event, context):
          route_key = event.get("routeKey", "")

          if route_key == "GET /health":
              return {
                  "statusCode": 200,
                  "headers": {"content-type": "application/json"},
                  "body": json.dumps({
                      "ok": True,
                      "service": "lambda-api",
                      "environment": os.getenv("ENVIRONMENT")
                  })
              }

          if route_key == "POST /events":
              body = {}
              raw_body = event.get("body")

              if raw_body:
                  try:
                      body = json.loads(raw_body)
                  except Exception:
                      body = {"raw": raw_body}

              sns.publish(
                  TopicArn=os.getenv("SNS_TOPIC_ARN"),
                  Message=json.dumps(body)
              )

              return {
                  "statusCode": 200,
                  "headers": {"content-type": "application/json"},
                  "body": json.dumps({
                      "message": "event published",
                      "ddb_table": os.getenv("DDB_TABLE"),
                      "db_proxy_host": os.getenv("DB_PROXY_HOST"),
                      "cache_host": os.getenv("CACHE_HOST")
                  })
              }

          return {
              "statusCode": 404,
              "headers": {"content-type": "application/json"},
              "body": json.dumps({"message": "route not found"})
          }
    PY
    filename = "index.py"
  }
}

resource "aws_lambda_function" "api_handler" {
  function_name = "${var.project_name}-${var.environment}-api-handler"
  role          = aws_iam_role.lambda_api.arn
  runtime       = var.lambda_runtime
  handler       = "index.handler"
  timeout       = var.lambda_timeout_seconds
  memory_size   = var.lambda_memory_mb
  kms_key_arn   = aws_kms_key.main.arn

  filename         = data.archive_file.lambda_api_zip.output_path
  source_code_hash = data.archive_file.lambda_api_zip.output_base64sha256

  vpc_config {
    subnet_ids         = [for subnet in aws_subnet.private : subnet.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DDB_TABLE     = aws_dynamodb_table.app.name
      DB_SECRET_ARN = aws_secretsmanager_secret.db.arn
      DB_PROXY_HOST = aws_db_proxy.main.endpoint
      DB_NAME       = var.db_name
      CACHE_HOST    = aws_elasticache_serverless_cache.main.endpoint[0].address
      CACHE_PORT    = "6379"
      SNS_TOPIC_ARN = aws_sns_topic.app_events.arn
      ENVIRONMENT   = var.environment
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-api-handler"
  }

  depends_on = [aws_cloudwatch_log_group.lambda_api]
}

resource "aws_apigatewayv2_api" "lambda_http" {
  name          = "${var.project_name}-${var.environment}-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["content-type", "authorization"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = ["*"]
    max_age       = 300
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-http-api"
  }
}

resource "aws_apigatewayv2_integration" "lambda_api" {
  api_id                 = aws_apigatewayv2_api.lambda_http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api_handler.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 10000
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.lambda_http.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_api.id}"
}

resource "aws_apigatewayv2_route" "events" {
  api_id    = aws_apigatewayv2_api.lambda_http.id
  route_key = "POST /events"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_api.id}"
}

resource "aws_cloudwatch_log_group" "apigw_http" {
  name              = "/apigw/${var.project_name}/${var.environment}/http-api"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.main.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-http-api-logs"
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.lambda_http.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_http.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      sourceIp       = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 100
    throttling_rate_limit    = 50
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-http-api-default-stage"
  }
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_http.execution_arn}/*/*"
}