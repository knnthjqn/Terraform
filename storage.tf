resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-${var.environment}-bucket-logs"

  tags = {
    name = "${var.project_name}-${var.environment}-bucket-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.bucket
  block_public_bucket = true
  block_public_acls = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs"{
  bucket = aws_s3_bucket.logs.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_key_id = aws_kms_key.id.arn
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket" "media" {
  bucket = "${var.project_name}-${var.environment}-bucket-media"

  tags = {
    Name = "${var.project_name}-${var.environment}-bucket-media"
  }
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.bucket

  versioning_configuration {
    enabled = true
  }

  tags = {
    name = "${var.project_name}-${var.environment}-bucket-versioning"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_key_id = aws_kms_key.id
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.bucket
  block_public_bucket = true
  block_public_acls = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucet_lifecycle_configuration" "media" {
  bucket = aws_s3_bucket.media.bucket

  rule {
    id = "expire-old-buckets"
    status = "enabled"
  }

  noncurrent_version_expiration {
    noncurrent_days = 30
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-bucket-lifecycle"
  }
}