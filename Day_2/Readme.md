# 🚀 Terraform — Day 2 Complete Guide

> Providers · Variables · Resources · tfvars · Multi-Provider · Multi-Region

---

## 📚 Table of Contents
1. [What is Terraform?](#what-is-terraform)
2. [Providers](#providers)
3. [Multiple Providers](#multiple-providers)
4. [Multiple Regions](#multiple-regions)
5. [Resources](#resources)
6. [Variables](#variables)
7. [terraform.tfvars](#terraformtfvars)
8. [Outputs](#outputs)
9. [Locals](#locals)
10. [Conditional Expressions](#conditional-expressions)
11. [Built-in Functions](#built-in-functions)
12. [Modules](#modules)
13. [Cheat Sheet](#cheat-sheet)

---

## What is Terraform?

Terraform is an **Infrastructure as Code (IaC)** tool.
Instead of clicking the AWS Console — you write code and Terraform creates everything automatically.
```
Without Terraform:  You → Console → Click → VPC → Click → Subnet → Click...
With Terraform:     You → Write code → terraform apply → Done ✅
```

### Basic Commands
```bash
terraform init      # download provider plugins (always first)
terraform plan      # preview what will be created
terraform apply     # actually create infrastructure
terraform destroy   # delete everything
terraform fmt       # auto format your code
terraform validate  # check syntax errors
```

---

## Providers

A **provider** is a plugin connecting Terraform to a cloud platform.
Think of it as a **translator** between your code and AWS/GCP/Azure.

### Basic AWS Provider
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

### Authentication — Right Way
```bash
# ❌ Never hardcode credentials in code
# ✅ Set as environment variables
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG"
export AWS_DEFAULT_REGION="us-east-1"
```

---

## Multiple Providers

Use more than one cloud in the same project.
```hcl
terraform {
  required_providers {
    aws    = { source = "hashicorp/aws",    version = "~> 5.0" }
    google = { source = "hashicorp/google", version = "~> 4.0" }
  }
}

provider "aws"    { region = "us-east-1" }
provider "google" { project = "my-gcp-project", region = "us-central1" }

# EC2 on AWS
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

# VM on Google Cloud
resource "google_compute_instance" "ml" {
  name         = "ml-server"
  machine_type = "n1-standard-4"
  zone         = "us-central1-a"
  boot_disk {
    initialize_params { image = "debian-cloud/debian-11" }
  }
  network_interface { network = "default" }
}
```
> **Real example:** Main app on AWS, ML workloads on GCP, Active Directory on Azure — all in one project!

---

## Multiple Regions

Deploy same resource in different AWS regions using `alias`.
```hcl
provider "aws" { region = "us-east-1" }           # default (USA)
provider "aws" { alias = "eu",   region = "eu-west-1" }   # Europe
provider "aws" { alias = "asia", region = "ap-south-1" }  # Asia/India

# Server in USA — no alias needed
resource "aws_instance" "server_us" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = { Name = "server-usa" }
}

# Server in Europe — specify alias
resource "aws_instance" "server_eu" {
  provider      = aws.eu
  ami           = "ami-0d71ea30463e0ff49"
  instance_type = "t2.micro"
  tags = { Name = "server-europe" }
}

# Server in Asia — specify alias
resource "aws_instance" "server_asia" {
  provider      = aws.asia
  ami           = "ami-0f5ee92e2d63afc18"
  instance_type = "t2.micro"
  tags = { Name = "server-india" }
}
```
> Users in India hit Asia server ⚡, Users in UK hit Europe server ⚡, instead of all going to USA 🐌

---

## Resources

Resources are the **actual things you want Terraform to create**.
```hcl
resource "PROVIDER_TYPE" "YOUR_LABEL" {
  argument = "value"
}
```
```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "main-vpc" }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id      # reference vpc above
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "public-subnet" }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "private-subnet" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "main-igw" }
}

# Security Group
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  tags = { Name = "web-server" }
}

# S3 Bucket
resource "aws_s3_bucket" "assets" {
  bucket = "myapp-assets-2024"
  tags = { Name = "assets" }
}

# RDS Database
resource "aws_db_instance" "db" {
  identifier          = "myapp-db"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "mydb"
  username            = "admin"
  password            = var.db_password    # use variable!
  skip_final_snapshot = true
}
```

### Referencing Other Resources
```hcl
aws_vpc.main.id                   # ID of VPC
aws_subnet.public.id              # ID of subnet
aws_instance.web.public_ip        # Public IP of EC2
aws_db_instance.db.endpoint       # DB connection endpoint
```

---

## Variables

Variables let you avoid hardcoding values — makes code reusable.

### `variables.tf`
```hcl
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "dev / staging / prod"
  type        = string
  # no default = user MUST provide this
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "enable_monitoring" {
  type    = bool
  default = false
}

variable "allowed_ports" {
  type    = list(number)
  default = [80, 443, 22]
}

variable "common_tags" {
  type = map(string)
  default = {
    Project   = "MyApp"
    ManagedBy = "Terraform"
  }
}

variable "db_password" {
  type      = string
  sensitive = true    # hidden from logs and terminal output
}

# With validation
variable "env_validated" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.env_validated)
    error_message = "Must be dev, staging, or prod."
  }
}
```

### Variable Types
```hcl
type = string         # "hello"
type = number         # 42
type = bool           # true / false
type = list(string)   # ["a", "b", "c"]
type = list(number)   # [80, 443]
type = map(string)    # { key = "value" }
```

### Using Variables in `main.tf`
```hcl
provider "aws" {
  region = var.region
}

resource "aws_instance" "web" {
  instance_type = var.instance_type
  monitoring    = var.enable_monitoring

  tags = merge(var.common_tags, {
    Name        = "web-server"
    Environment = var.environment
  })
}
```

---

## terraform.tfvars

The file where you **fill in values** for your variables — like a `.env` file.
```
variables.tf      →  declares variable names (the empty boxes)
terraform.tfvars  →  fills in the values     (puts stuff in boxes)
```

### `terraform.tfvars`
```hcl
region        = "us-east-1"
environment   = "dev"
instance_type = "t2.micro"
db_password   = "MySecretPass123!"

common_tags = {
  Project   = "MyApp"
  Owner     = "DevTeam"
  ManagedBy = "Terraform"
}
```

### Different tfvars per environment
```hcl
# dev.tfvars
environment   = "dev"
instance_type = "t2.micro"      # small + cheap
db_password   = "DevPass123"

# staging.tfvars
environment   = "staging"
instance_type = "t2.medium"
db_password   = "StagingPass456"

# prod.tfvars
environment   = "prod"
instance_type = "t3.large"      # powerful
db_password   = "SuperSecureProd!"
region        = "eu-west-1"     # Europe for prod
```
```bash
terraform apply                          # auto-loads terraform.tfvars
terraform apply -var-file="dev.tfvars"
terraform apply -var-file="prod.tfvars"
```

---

## Outputs

Display values after `terraform apply` runs.
```hcl
# outputs.tf
output "web_server_ip" {
  value = aws_instance.web.public_ip
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "db_endpoint" {
  value     = aws_db_instance.db.endpoint
  sensitive = true                          # hides from terminal
}
```

After apply:
```
Outputs:
web_server_ip = "54.123.456.789"
vpc_id        = "vpc-0abc1234"
```

---

## Locals

Computed values you define once and reuse everywhere.
```hcl
locals {
  app_name    = "myapp"
  environment = var.environment

  vpc_name = "${local.app_name}-${local.environment}-vpc"
  ec2_name = "${local.app_name}-${local.environment}-server"

  common_tags = {
    App         = local.app_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = merge(local.common_tags, { Name = local.vpc_name })
}
```

---

## Conditional Expressions

If-else logic in Terraform.
```hcl
# Syntax: condition ? if_true : if_false

resource "aws_instance" "web" {
  instance_type = var.environment == "prod" ? "t3.large" : "t2.micro"
}

resource "aws_db_instance" "db" {
  multi_az                = var.environment == "prod" ? true : false
  backup_retention_period = var.environment == "prod" ? 7 : 0
  allocated_storage       = var.environment == "prod" ? 100 : 20
}

resource "aws_instance" "app" {
  subnet_id = var.is_public ? aws_subnet.public.id : aws_subnet.private.id
}
```

---

## Built-in Functions
```hcl
# String
upper("hello")               # → "HELLO"
lower("HELLO")               # → "hello"
length("hello")              # → 5
replace("hello", "l", "r")  # → "herro"
trimspace("  hi  ")          # → "hi"
format("server-%02d", 5)     # → "server-05"

# List
length(["a","b","c"])            # → 3
element(["a","b","c"], 0)        # → "a"
contains(["a","b"], "b")         # → true
join(", ", ["a","b","c"])        # → "a, b, c"
concat(["a"],["b","c"])          # → ["a","b","c"]
sort(["c","a","b"])              # → ["a","b","c"]

# Map
keys({a=1, b=2})                 # → ["a","b"]
values({a=1, b=2})               # → [1, 2]
merge({a=1},{b=2})               # → {a=1, b=2}
```

---

## Modules

Write once → use many times. Like a function for infrastructure.

### Module folder
```
modules/
└── vpc/
    ├── variables.tf   ← inputs
    ├── main.tf        ← resources
    └── outputs.tf     ← return values
```

**`modules/vpc/variables.tf`**
```hcl
variable "project_name"         { type = string }
variable "vpc_cidr"             { type = string  default = "10.0.0.0/16" }
variable "public_subnet_cidr"   { type = string  default = "10.0.1.0/24" }
variable "private_subnet_cidr"  { type = string  default = "10.0.2.0/24" }
```

**`modules/vpc/main.tf`**
```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = { Name = "${var.project_name}-vpc" }
}
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr
  tags       = { Name = "${var.project_name}-public" }
}
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr
  tags       = { Name = "${var.project_name}-private" }
}
```

**`modules/vpc/outputs.tf`**
```hcl
output "vpc_id"            { value = aws_vpc.main.id }
output "public_subnet_id"  { value = aws_subnet.public.id }
output "private_subnet_id" { value = aws_subnet.private.id }
```

**`main.tf` — call module 3 times**
```hcl
module "website_vpc" {
  source              = "./modules/vpc"
  project_name        = "website"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
}

module "mobile_vpc" {
  source              = "./modules/vpc"      # SAME module!
  project_name        = "mobile"
  vpc_cidr            = "10.1.0.0/16"       # different IPs
  public_subnet_cidr  = "10.1.1.0/24"
  private_subnet_cidr = "10.1.2.0/24"
}

# Use module output
resource "aws_instance" "web" {
  subnet_id = module.website_vpc.public_subnet_id   # ← module output
}
```

---

## Cheat Sheet

| File                | Purpose                                   |
|---------------------|-------------------------------------------|
| `main.tf`           | Resources, providers, module calls        |
| `variables.tf`      | Variable declarations                     |
| `terraform.tfvars`  | Variable values                           |
| `outputs.tf`        | Values to show after apply                |
| `locals.tf`         | Internal computed constants               |

| CIDR            | Used For   | IPs       |
|-----------------|------------|-----------|
| `10.0.0.0/16`  | VPC        | 65,536    |
| `10.0.1.0/24`  | Subnet     | 256       |
| `0.0.0.0/0`    | All traffic| All IPs   |

| Port  | Use              |
|-------|------------------|
| 22    | SSH              |
| 80    | HTTP             |
| 443   | HTTPS            |
| 3306  | MySQL            |
| 5432  | PostgreSQL       |
| 6379  | Redis            |

### Resource creation order
```
1. VPC
2. Subnets
3. Internet Gateway
4. Route Tables
5. Security Groups
6. NAT Gateway
7. EC2 / RDS / etc.
```

---
*🔥 Day 2 done — keep the streak alive!*