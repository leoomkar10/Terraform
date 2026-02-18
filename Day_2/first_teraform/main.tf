module "my_ec2" {
    source = "./module/ec2_instance_"
    ami_id = var.ami_id
    instance_type = var.instance_type
    subnet_id = var.subnet_id
    instance_name = var.instance_name
}