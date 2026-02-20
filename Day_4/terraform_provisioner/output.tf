output "instance_public_ip" {
    value = aws_instance.my_instance.public_ip
}


output "app_url" {
    value = "http://${aws_instance.my_instance.public_ip}:8000"
}