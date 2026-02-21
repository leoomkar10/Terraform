provider "aws" {
    region = "ap-south-1"
}

resource "aws_instance" "my_instance" {
    ami = var.ami
    instance_type = lookup(var.instance_type, terraform.workspace, "t2.micro")
    subnet_id = var.subnet_id

    tags = {
        Name = "${terraform.workspace}-instance"
    }
}