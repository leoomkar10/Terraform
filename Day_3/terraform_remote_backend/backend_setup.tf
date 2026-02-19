resource "aws_s3_bucket" "my_bucket" {
    bucket = "terraform-bucket-2003-og"

    tags = {
        Name = "Terraform S3 Bucket"
    }    
}

resource "aws_s3_bucket_versioning" "my_bucket_versioning" {
  bucket = aws_s3_bucket.my_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "my_dynamodb_table" {
    name = "terraform-lock-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }

    tags = {
        Name = "Terraform DynamoDB Table"
    }
}