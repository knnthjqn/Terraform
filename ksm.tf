resource "aws_kms_key" "main" {
  description = "${var.project_name}-kms-key"
  deletion_window_in_days = 30
  enable_key_rotation = true

  tags = merge(local.common_tags, {
    Name = "aws_kms_key"
  })
}

resource "aws_kms_alias" "main" {
  name = "${var.project_name}-kms-key-alias"
  target_key_id = aws_kms_key.main.id
}