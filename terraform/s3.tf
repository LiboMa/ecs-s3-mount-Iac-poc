# S3 Bucket for testing
resource "aws_s3_bucket" "test_bucket" {
  bucket = local.bucket_name
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "test_bucket" {
  bucket = aws_s3_bucket.test_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "test_bucket" {
  bucket = aws_s3_bucket.test_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Upload test files to S3
resource "aws_s3_object" "test_file" {
  bucket  = aws_s3_bucket.test_bucket.id
  key     = "test-data/sample.txt"
  content = "Hello from S3! This is a test file for ECS S3 mount.\nTimestamp: ${timestamp()}"
  tags    = local.common_tags
}

resource "aws_s3_object" "test_json" {
  bucket  = aws_s3_bucket.test_bucket.id
  key     = "test-data/config.json"
  content = jsonencode({
    app_name    = "ecs-s3-test"
    version     = "1.0.0"
    environment = "test"
    timestamp   = timestamp()
  })
  tags = local.common_tags
}