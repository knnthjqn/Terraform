resource "aws_s3_bucket" "media" {
    bucket = "${var.project_name}-media-bucket-${data.aws_caller_identity.current.id}"
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
            sse_algorithm = "aws:kms"
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

resource "aws_s3_bucket" "deploy_artifacts" {
    bucket = "${var.project_name}-${environment}-deploy-artifacts-${data.aws_caller_identity.current.id}
}

resource "aws_s3_bucket_versioning" "deploy_artifacts" {
    bucket = aws_s3_bucket.deploy_artifacts.id

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deploy_artifacts" {
    bucket = aws_s3_bucket.deploy_artifacts.id

    rule {
        apply_server_side_encryption_by_default {
            kms_key_id = aws_kms_key.main.id
            sse_algorithm = "aws:kms"
        }
    }
}

resource "aws_s3_bucket_public_access_block" "deploy_artifacts" {
    bucket = aws_s3_bucket.deploy_artifacts.id

    block_public_policy = true
    block_public_acls = true
    ignore_public_acls = true
    restrict_public_buckets = true
}
