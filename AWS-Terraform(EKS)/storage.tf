resource "aws_s3_bucket" "logs" {
    bucket = "${var.project_name}-${var.environment}-logs-bucket"

    tags = {
        name = "${var.project_name}-${var.environment}-logs-bucket"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
    bucket = aws_s3_bucket.logs.bucket

    rule {
        apply_server_side_encryption_by_default {
            kms_key_id = aws_kms_key.main.arn
            sse_algorithm = "aws:kms"
        }
    }
}

resource "aws_s3_bucket_public_access_block" "logs" {
    bucket = aws_s3_bucket.logs.bucket
    
    block_public_policy = true
    block_public_acls = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket" "media" {
    bucket = "${var.project_name}-${var.environment}-media-bucket"

    tags = {
        name = "${var.project_name}-${var.environment}-media-bucket"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
    bucket = aws_s3_bucket.media.bucket

    rule {
        apply_server_side_encryption_by_default {
            kms_key_id = aws_kms_key.main.arn
            sse_algorithm = "aws:kms"
        }
    }
}

resource "aws_s3_bucket_versioning" "media" {
    bucket = aws_s3_bucket.media.bucket

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_public_access_block" "media" {
    bucket = aws_s3_bucket.media.bucket

    block_public_policy = true
    block_public_acls = true
    ignore_public_acls = true
    restrict_public_buckets = true
}