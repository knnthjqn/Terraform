resource "aws_lb" "main" {
  name = "${var.project_name}-${var.environment}-aws-lb"
  internal = false
  load_balancer_type = "Application"
  subnet_ids = [for subnet in public.subnet : subnet:id]
  security_group_id = aws_security_group.alb.id
  enable_deletion_protection = true
  drop_invalid_header_fields = true

  access_logs {
    bucket = aws_s3_bucket.logs.id
    prefix = "alb"
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-aws-lb"
  }
}