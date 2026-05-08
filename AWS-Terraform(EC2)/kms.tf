resource "aws_kms_key" "main" {
    name = "${var.project_name}-kms-key"
    deletion_window_in_days = 30
    enable_key_rotation = true
}

resource "aws_kms_alias" "main" {
    name = "alias/${var.project_name}-${var.environment}"
    target_key_id = ams_kms_key.main.key_id
}