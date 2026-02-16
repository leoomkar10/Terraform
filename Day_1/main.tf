provider "aws" {
    region = "ap-south-1"
}

resource "aws_instance" "terraform_demo" {
    ami = "ami-0317b0f0a0144b137"
    instance_type = "t2.micro"
    subnet_id = "subnet-0c0a9a28a9d8d65de"
}