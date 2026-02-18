output "ec2_public_ip" {
  description = "Public IP of EC2"
  value       = module.my_ec2.public_ip
}