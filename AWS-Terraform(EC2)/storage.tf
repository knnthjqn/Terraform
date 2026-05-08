resource "aws_s3_bucket" "media" {
    bucket = "${var.project_name}-${var.environment}-media-bucket"
}

resource "aws_s3_bucket_versioning" "media" {
    bucket = aws_s3_bucket.media.id

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
    bucket = aws_s3_bucket.media.id

    rule {
        apply_server_side_encryption_by_default {
            kms_key_id = aws_kms_key.main.arn
            see_algorithm = "aws:key"
        }
    }
}

resource "aws_s3_bucket_public_access_block" "media" {
    bucket = aws_s3_bucket.media.id

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}
