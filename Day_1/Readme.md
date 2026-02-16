# 🚀 Day 1 – Terraform Basics & EC2 Creation

## 📌 What is Terraform?
Terraform is an Infrastructure as Code (IaC) tool created by HashiCorp.
It allows us to create, manage, and automate cloud infrastructure using code instead of manually creating resources from the cloud console.
With Terraform, we define infrastructure in a configuration file (`.tf` file), and Terraform provisions the resources automatically.

## 🔥 Why Terraform is Mostly Used?
Terraform is widely used because:
* ✅ It supports multi-cloud (AWS, Azure, GCP)
* ✅ Uses simple and readable language (HCL)
* ✅ Infrastructure can be version controlled using Git
* ✅ Provides state management
* ✅ Idempotent (running again does not create duplicates)
* ✅ Easy integration with CI/CD pipelines

It helps DevOps engineers automate infrastructure safely and efficiently.

## ⚖️ How Terraform is Different from CloudFormation, Azure ARM & GCP

| Feature | Terraform | AWS CloudFormation | Azure ARM | GCP Deployment Manager |
|---------|-----------|-------------------|-----------|----------------------|
| Multi-cloud | ✅ Yes | ❌ No (AWS only) | ❌ No (Azure only) | ❌ No (GCP only) |
| Language | HCL (Simple) | JSON / YAML | JSON | YAML / Python |
| Vendor Lock-in | ❌ No | ✅ Yes | ✅ Yes | ✅ Yes |
| Community Support | Very Large | AWS Focused | Azure Focused | GCP Focused |

Terraform is cloud-agnostic, while the others are cloud-specific tools.

## 🖥️ How I Installed Terraform (Windows)

### Step 1: Open PowerShell as Administrator
* Click Start
* Search PowerShell
* Right click → Run as Administrator

### Step 2: Install Terraform
Using Chocolatey:
```bash
choco install terraform -y
```

### Step 3: Verify Installation
```bash
terraform -v
```

If it shows the version, installation is successful.

## ☁️ First EC2 Instance Using Terraform

### Step 1: Create Project Folder
```bash
mkdir Day_1
cd Day_1
```

### Step 2: Create `main.tf`
```hcl
provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "terraform_demo" {
  ami           = "ami-0317b0f0a0144b137"
  instance_type = "t2.micro"

  tags = {
    Name = "Omkar-Terraform-EC2"
  }
}
```

### Step 3: Initialize Terraform
```bash
terraform init
```

### Step 4: Check Execution Plan
```bash
terraform plan
```

### Step 5: Apply Configuration
```bash
terraform apply
```

Type:
```
yes
```

Terraform successfully created an EC2 instance in AWS.

### Step 6: Destroy Resource (Important)
```bash
terraform destroy
```

Type:
```
yes
```

This removes the created infrastructure to avoid extra AWS costs.
