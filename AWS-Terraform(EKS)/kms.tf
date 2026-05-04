resource "aws_kms_key" "main" {
    name = "${var.project_name}-${var.environment}-kms-key"
    deletion_window_in_days = 30
    enable_key_rotation = true

    tags = {
        name = name = "${var.project_name}-${var.environment}-kms-key"
    }
}

resource "aws_kms_alias" "main" {
    name = name = "alias/${var.project_name}-${var.environment}"
    target_key_id = aws_kms_key.main.id    
}