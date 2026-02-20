# 📦 Day 4 — Terraform Provisioners

## Table of Contents
- [What is a Provisioner?](#what-is-a-provisioner)
- [Why Do We Need Provisioners?](#why-do-we-need-provisioners)
- [When Should You Use Provisioners?](#when-should-you-use-provisioners)
- [Types of Provisioners](#types-of-provisioners)
  - [file Provisioner](#1-file-provisioner)
  - [remote-exec Provisioner](#2-remote-exec-provisioner)
  - [local-exec Provisioner](#3-local-exec-provisioner)
- [The connection Block](#the-connection-block)
- [on_failure & when](#on_failure--when-destroy)
- [Provisioner vs Alternatives](#provisioner-vs-alternatives)
- [Key Takeaways](#key-takeaways)

---

## What is a Provisioner?

When Terraform creates infrastructure (like an EC2 instance), it only handles the **infrastructure layer** — it provisions the machine but doesn't configure it.

A **Provisioner** is a way to tell Terraform:
> *"After you create this resource, also run these commands or copy these files."*

Think of it like a **post-creation setup step** — Terraform builds the house, and the provisioner furnishes it.

```
terraform apply
     │
     ▼
Create EC2 Instance          ← Terraform handles this
     │
     ▼
Copy app.py → EC2            ← file provisioner
     │
     ▼
Install Python, Run App      ← remote-exec provisioner
     │
     ▼
Log IP to local file         ← local-exec provisioner
```

> ⚠️ **Terraform's Official Advice**: Provisioners are a **last resort**. Prefer `user_data`, cloud-init, or tools like Ansible when possible. But for learning, they're great!

---

## Why Do We Need Provisioners?

| Without Provisioner | With Provisioner |
|---|---|
| EC2 is created, nothing runs on it | EC2 is created + app is installed and running |
| You have to SSH manually and set up | Terraform automates the entire setup |
| Infrastructure ≠ Application | Infrastructure + Application in one `apply` |

---

## When Should You Use Provisioners?

✅ **Use provisioners when:**
- You want to copy config/app files to a server
- You need to install packages right after server creation
- You want to trigger a local script after infra is created (e.g., notify a Slack channel)
- You're learning Terraform and want quick automation

❌ **Avoid provisioners when:**
- You're in production — use `user_data` or Ansible instead
- The task is complex configuration management
- You need idempotency (provisioners only run once at creation)

---

## Types of Provisioners

---

### 1. `file` Provisioner

**What it does:** Copies a file or folder from your **local machine → remote server**

**When to use it:** When your EC2 needs a config file, app file, or script that exists on your machine

#### Syntax
```hcl
provisioner "file" {
  source      = "app.py"                    # local path (relative to main.tf)
  destination = "/home/ubuntu/app.py"       # remote path on EC2
}
```

#### Copy an entire folder
```hcl
provisioner "file" {
  source      = "configs/"                  # local folder
  destination = "/home/ubuntu/configs"      # remote folder
}
```

> 🔑 Needs a `connection` block to know how to reach the server (SSH details)

---

### 2. `remote-exec` Provisioner

**What it does:** Runs commands **on the remote EC2 instance** via SSH after it's created

**When to use it:** Installing packages, starting services, running setup scripts on the server

#### Syntax — inline commands
```hcl
provisioner "remote-exec" {
  inline = [
    "sudo apt-get update -y",
    "sudo apt-get install -y python3 python3-pip",
    "pip3 install flask --break-system-packages",
    "nohup python3 /home/ubuntu/app.py &"
  ]
}
```

#### Syntax — external script file
```hcl
provisioner "remote-exec" {
  script = "scripts/setup.sh"    # local script, uploaded and run on remote
}
```

#### Syntax — multiple script files
```hcl
provisioner "remote-exec" {
  scripts = [
    "scripts/install.sh",
    "scripts/configure.sh",
    "scripts/start.sh"
  ]
}
```

> 🔑 Needs a `connection` block to SSH into the server

---

### 3. `local-exec` Provisioner

**What it does:** Runs commands **on your local machine** (where `terraform apply` is running)

**When to use it:** Logging output, updating Ansible inventory, sending notifications, triggering pipelines

#### Syntax
```hcl
provisioner "local-exec" {
  command = "echo 'EC2 created with IP: ${self.public_ip}' >> servers.txt"
}
```

#### With environment variables
```hcl
provisioner "local-exec" {
  command = "python3 notify.py"
  environment = {
    SERVER_IP   = self.public_ip
    SERVER_NAME = self.tags["Name"]
  }
}
```

#### Run a Python/Ansible command locally
```hcl
provisioner "local-exec" {
  command = "ansible-playbook -i '${self.public_ip},' playbook.yml"
}
```

> 🔑 Does NOT need a `connection` block — it runs on your machine, not the server

---

## The `connection` Block

The `connection` block tells Terraform **how to SSH into the remote server**. It is required for `file` and `remote-exec` provisioners.

```hcl
resource "aws_instance" "my_instance" {
  # ... instance config ...

  connection {
    type        = "ssh"                      # ssh (Linux) or winrm (Windows)
    user        = "ubuntu"                   # ubuntu for Ubuntu AMI, ec2-user for Amazon Linux
    private_key = file("~/.ssh/id_rsa")     # path to your private key
    host        = self.public_ip             # self = the current resource (EC2)
  }
}
```

### Connection inside provisioner (applies to one provisioner only)
```hcl
provisioner "remote-exec" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  inline = ["echo hello"]
}
```

### Connection at resource level (applies to ALL provisioners in the resource)
```hcl
resource "aws_instance" "my_instance" {
  # ...

  connection {                          # 👈 applies to ALL provisioners below
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "file" { ... }           # uses the connection above
  provisioner "remote-exec" { ... }    # uses the connection above
}
```

---

## `on_failure` & `when` (Destroy)

### `on_failure` — what happens if provisioner fails?

```hcl
provisioner "remote-exec" {
  inline = ["sudo apt install nginx"]

  on_failure = continue   # ✅ ignore failure, keep going
  # on_failure = fail     # ❌ stop everything (this is the default)
}
```

### `when = destroy` — run provisioner at destroy time

```hcl
provisioner "local-exec" {
  when    = destroy
  command = "echo 'Server ${self.id} is being destroyed' >> destroy.log"
}
```

This is useful for:
- Deregistering a server from a load balancer before termination
- Sending a notification when infrastructure is torn down
- Cleanup tasks before a resource is deleted

---


### ❌ Error: `externally-managed-environment` (pip3 install fails)
**Cause:** Ubuntu 22.04+ blocks global pip installs (PEP 668)

**Fix:** Add `--break-system-packages` flag
```bash
pip3 install flask --break-system-packages
```

---

### ❌ App not running after `terraform apply`
**Cause:** `nohup python3 app.py &` process gets killed when SSH session disconnects

**Fix:** Use `systemd` service instead of `nohup`:
```bash
sudo systemctl start helloapp
sudo systemctl status helloapp
```

---

### ❌ Browser shows "Connection Refused"
**Cause:** Port 8000 missing from Security Group inbound rules

**Fix:** Add ingress rule for port 8000 in your security group, then run `terraform apply`

---

### ❌ SSH connection timeout during provisioner
**Cause:** Instance not fully booted yet when provisioner tries to connect

**Fix:** Add a `timeouts` block:
```hcl
resource "aws_instance" "my_instance" {
  # ...
  timeouts {
    create = "10m"
  }
}
```

---

## Provisioner vs Alternatives

| Approach | Best For | Pros | Cons |
|---|---|---|---|
| `remote-exec` | Quick setup, learning | Simple, no extra tools | Runs once, not idempotent |
| `local-exec` | Local triggers, notifications | No SSH needed | Runs on your machine only |
| `user_data` | Boot scripts on EC2 | Native AWS, no SSH needed | Can't verify if it succeeded |
| Ansible | Complex configuration | Idempotent, reusable | Extra tool to learn |
| Packer | Baking AMIs with pre-installed software | Fast boot, no setup needed | Longer build pipeline |

---

## Key Takeaways

- A **provisioner** runs after Terraform creates a resource — it's the "setup after creation" step
- **`file`** → copies files from local to remote
- **`remote-exec`** → runs commands on the remote server via SSH
- **`local-exec`** → runs commands on your local machine
- Always add a **`connection` block** when using `file` or `remote-exec`
- Use **`systemd` service** instead of `nohup` to keep apps running after SSH disconnects
- Use **`--break-system-packages`** flag with pip3 on Ubuntu 22.04+
- Use **`when = destroy`** to run cleanup tasks before a resource is deleted
- Provisioners are a **last resort** — prefer `user_data` or Ansible in production