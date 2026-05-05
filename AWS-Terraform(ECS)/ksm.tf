resource "aws_kms_key" "main" {
  name = "${var.project_name}-${environment}-kms"
  deletion_window_in_days = 30
  enable_key_rotation = true

  tags = {
    Name = "${var.project_name}-${environment}-kms"
  }
}

resource "aws_kms_alias" "main" {
  name = "${var.project_name}-${environment}-kms-alias"
  target_key_id = aws_kms_key.main.id
}