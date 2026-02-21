variable ami {
    description = "The AMI ID to use for the instance"
    type        = string
}

variable "instance_type" {
    description = "The type of instance to use"
    type        = map(string)

    default = {
        "dev" = "t2.micro",
        "stage" = "t2.medium",
        "prod" = "t2.large"
    }
}

variable "subnet_id" {
    description = "The ID of the subnet to launch the instance in"
    type        = string
}