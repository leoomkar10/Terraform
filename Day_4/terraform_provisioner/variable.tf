variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_blocks" {
  description = "A list of CIDR blocks for the subnets."
  type        = string
  default     = "10.0.0.0/24"
}

variable "ami_id"{
    default = "ami-019715e0d74f695be"
}
