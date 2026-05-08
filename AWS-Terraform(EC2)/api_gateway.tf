resource "aws_apigatewayv2_vpc_link" "ec2" {
    name = "${var.project_name}-${var.environment}-ec2-vpc-link"
    subnet_ids = [for subnet in aws_subnet.private : subnet:id]
    security_group_ids = [aws_security_group.apigw_vpc_link.id]
}

resource "aws_apigatewayv2_api" "ec2" {
    nane = "${var.project_name}-${var.environment}-ec2-api"
    protocol = "http"
}

resource "aws_apigatewayv2_integration" "ec2" {
    api_id = aws_apigatewayv2_api.ec2.id
    integration_type = "HTTP_PROXY"
    integration_method = "ANY"
    integration_uri = aws_lb_listener.http.arn
    connection_type = "VPC_LINK"
    connection_id = aws_apigatewayv2_vpc_link.ec2.id
    timeout_milliseconds = 30000
}

resource "aws_apigatewayv2_route" "ec2_proxy" {
    api_id = aws_apigatewayv2_api.ec2.id
    route_key = "ANY/{proxy+}"
    target = "integration/${aws_apigatewayv2_integration.ec2.id}"
}