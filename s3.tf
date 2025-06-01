resource "random_id" "bucket_id" {
  byte_length = 4
}
resource "aws_s3_bucket" "snapshot_bucket" {
  bucket = "${var.prefix}-s3-20150514-${random_id.bucket_id.hex}"

  tags = {
    Name        = "SnapshotBackupBucket"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.snapshot_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}