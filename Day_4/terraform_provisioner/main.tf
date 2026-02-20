provider "aws" {
    region = "ap-south-1"
}

resource "aws_key_pair" "name" {
  key_name = "terraform-demo-omkar"
  public_key = file("C:/Users/omkar sunil gunjote/.ssh/id_rsa.pub")
}

resource "aws_vpc" "my_vpc" {
    cidr_block = var.cidr_block  
}

resource "aws_subnet" "my_subnet" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = var.subnet_cidr_blocks 
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "my_route_table" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }
}

resource "aws_route_table_association" "my_route_table_assoc" {
    subnet_id = aws_subnet.my_subnet.id
    route_table_id = aws_route_table.my_route_table.id
}

resource "aws_security_group" "my_sg" {
    name = "terraform-sg"
    description = "Allow SSH and HTTP traffic"
    vpc_id = aws_vpc.my_vpc.id

    ingress {
        description = "App Port 8000 from anywhere"
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "SSH from anywhere"
        from_port = 22
        to_port = 22        
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      name = "terraform-demo-sg"
    }
}

resource "aws_instance" "my_instance" {
    ami = var.ami_id
    instance_type = "t2.micro"
    subnet_id = aws_subnet.my_subnet.id
    vpc_security_group_ids = [aws_security_group.my_sg.id]
    key_name = aws_key_pair.name.key_name

    tags = {
      Name = "Terraform Demo instance"
    }

    connection {
        type = "ssh"
        user = "ubuntu"
        private_key = file("C:/Users/omkar sunil gunjote/.ssh/id_rsa")
        host = self.public_ip
    }

    provisioner "file" {
      source = "app.py"
      destination = "/home/ubuntu/app.py"
    }

    provisioner "remote-exec" {
      inline = [
        "sudo apt-get update -y",
        "sudo apt-get install -y python3 python3-venv",

        "cd /home/ubuntu",
        "python3 -m venv venv",

        # install flask inside venv
        "/home/ubuntu/venv/bin/pip install flask",

        # run app using venv python
        "nohup /home/ubuntu/venv/bin/python /home/ubuntu/app.py > output.log 2>&1 &"
        ]
    }

}
