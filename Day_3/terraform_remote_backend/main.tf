resource "aws_instance" "my_ec2_instance" {
    ami = "ami-051a31ab2f4d498f5"
    instance_type = "t2.micro"
    subnet_id = "****************"
    tags = {
        Name = "Terraform EC2"
    }
}