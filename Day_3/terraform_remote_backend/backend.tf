terraform {
  backend "s3" {
    bucket = "terraform-bucket-2003-og"
    key = "ec2/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "terraform-lock-table"
    encrypt = true
  }
}