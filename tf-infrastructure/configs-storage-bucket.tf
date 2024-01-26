/*
  THIS IS INSECURE AND BAD PRACTICES 
  TODO: FIX 
*/
resource "random_string" "random_hash" {
  length  = 8  # Length of the random hash
  special = false
  upper   = false
  lower   = true
}
resource "aws_s3_bucket" "configuration-storage-bucket" {
  bucket = "ccdc24testenv-${random_string.random_hash.result}"
}

resource "aws_s3_bucket_ownership_controls" "configuration-storage-bucket" {
  bucket = aws_s3_bucket.configuration-storage-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "configuration-storage-bucket" {
  bucket = aws_s3_bucket.configuration-storage-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "configuration-storage-bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.configuration-storage-bucket,
    aws_s3_bucket_public_access_block.configuration-storage-bucket,
  ]

  bucket = aws_s3_bucket.configuration-storage-bucket.id
  acl    = "public-read-write"
}

/*
TO UPLOAD A RESOURCE WITHIN TERRAFORM (EXAMPLE): 
resource "local_file" "example-upload" {
  content = <<-DOC
    Hello World
    DOC
  filename = "${path.module}/hello-world.txt"
}

resource "aws_s3_object" "configuration-storage-bucket-object" {
  bucket = aws_s3_bucket.configuration-storage-bucket.id
  key    = "hello-world.txt"
  source = local_file.example-upload.filename
}
*/
