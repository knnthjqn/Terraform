resource "aws_kms_key" "main" {
    name = "${var.project_name}-${var.environment}-kms"
    deletion_window_in_days = 30
    enable_key_rotation = true
}

resource "aws_kms_alias" "main" {
    name = "alias/${var.project_name}-${var.environment}"
    target_key_id = aws_kms_key.main.id
}