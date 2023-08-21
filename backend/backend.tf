# Create S3 Bucket
resource "aws_s3_bucket" "terraform_state" {
bucket = var.BucketName
lifecycle {
    prevent_destroy = false
    }
}

# S3 versioning enable
resource "aws_s3_bucket_versioning" "enabled" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
}
# Create KMS key
resource "aws_kms_key" "key" {
  description             = "For terraform S3"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

# Enable S3-SSE with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "default2" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.key.key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

# Explicitly block all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create DynamoDB table for terraform lock
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.DynamoDB
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}