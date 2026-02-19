# 🏗️ Terraform Remote Backend with S3 & DynamoDB Locking

A hands-on Terraform project demonstrating how to store Terraform state files remotely in AWS S3 and prevent concurrent modifications using DynamoDB locking.

---

## 📌 What is a Remote Backend?

In Terraform, a **backend** defines where the **state file (`terraform.tfstate`)** is stored.

By default, Terraform stores the state file **locally** on your machine. This works fine when you are working alone, but it creates serious problems in real-world team environments.

A **Remote Backend** moves the state file to a shared, centralized location — in this case, an **AWS S3 bucket** — so that everyone on the team works from the same source of truth.

---

## ❓ Why Do We Need a Remote Backend?

### The Problem with Local State

When the state file is stored locally:

- If the **state file gets deleted** → Terraform has no memory of what it already created → running `terraform apply` again creates **duplicate resources** (two EC2 instances, two S3 buckets, etc.)
- If you are working in a **team** → every team member has a different local state file → conflicts and inconsistencies
- No **locking mechanism** → two people can run `terraform apply` at the same time → infrastructure gets corrupted

---

## 🌍 Real World Scenario

Imagine you work at a company where **Raj and Priya** are both DevOps Engineers managing the same AWS infrastructure using Terraform.

**Without Remote Backend:**

```
Raj   → runs terraform apply on his laptop (EC2 gets created)
Priya → runs terraform apply on her laptop (doesn't know Raj already created it)
        → Terraform creates ANOTHER EC2 instance
        → Now you have duplicate infrastructure 💥
        → AWS bill doubles!
```

**With Remote Backend (S3):**

```
Raj   → runs terraform apply
        → Terraform reads state from S3
        → Sees EC2 already exists → No duplicate ✅

Priya → runs terraform apply
        → Terraform reads the SAME state from S3
        → Sees EC2 already exists → No duplicate ✅
```

Both Raj and Priya are now working from the **same state file** stored in S3 — no conflicts, no duplicates.

---

## 🔒 What is DynamoDB Locking?

Even with S3 storing the state file, there is still one problem — what if **Raj and Priya run `terraform apply` at the exact same time?**

Both would read the same state file simultaneously and try to write changes at the same time → **state file corruption!**

This is where **DynamoDB locking** comes in.

### How It Works

DynamoDB acts like a **"token"** — only one person can hold it at a time:

```
Raj runs terraform apply
        ↓
Terraform writes a LOCK record in DynamoDB
(like putting a sign: "I AM USING THIS")
        ↓
Priya runs terraform apply at the same time
        ↓
Terraform checks DynamoDB → sees LOCK already exists
        ↓
Priya's apply is BLOCKED ❌
"Error: State is locked by Raj"
        ↓
Raj's apply finishes → LOCK record is deleted from DynamoDB
        ↓
Priya can now run apply ✅
```

### Real Life Analogy 🚽

Think of it like a **toilet with a lock**:

- **S3** = the toilet (shared resource everyone needs access to)
- **DynamoDB** = the lock on the door
- When Raj is inside → door is locked → Priya waits outside
- When Raj comes out → lock opens → Priya can go in
- **Without the lock** → both walk in at the same time → chaos! 💥

---

## 📁 Project Structure

```
terraform-remote-backend/
├── provider.tf          # AWS provider configuration
├── backend_setup.tf     # Creates S3 bucket and DynamoDB table
├── backend.tf           # Configures remote backend
├── main.tf              # Creates EC2 instance
└── .gitignore           # Ignores sensitive state files
```


## 🚀 How to Run This Project

### Step 1 — Initialize and create S3 + DynamoDB + EC2
Make sure `backend.tf` is **not added yet**, then run:
```bash
terraform init
terraform apply
```

### Step 2 — Add `backend.tf` and migrate state to S3
```bash
terraform init
```
When prompted:
```
Do you want to copy existing state to the new backend? yes
```

### Step 3 — Verify state file in S3
```
AWS Console → S3 → terraform-bucket-2003-og → ec2/terraform.tfstate
```

### Step 4 — Verify locking works
Open two terminals and run `terraform apply` in both simultaneously. The second terminal will show:
```
Error: Error acquiring the state lock
```
This proves DynamoDB locking is working! ✅

---

## 🧹 How to Destroy Everything

```bash
# Step 1 - Destroy EC2 first
terraform destroy -target="aws_instance.my_ec2_instance"

# Step 2 - Migrate state back to local
terraform init -migrate-state

# Step 3 - Destroy remaining resources
terraform destroy -lock=false
```

> ⚠️ **Note:** Because S3 versioning is enabled, you may need to manually empty the S3 bucket from the AWS Console before it can be deleted. Go to `S3 → your bucket → Show versions → Select all → Delete`.

---

## 💰 AWS Free Tier Cost

| Resource | Free Tier Limit | Usage in this project |
|---|---|---|
| S3 Bucket | 5GB storage, 20K GET / 2K PUT | State file is only a few KBs — well within limits ✅ |
| DynamoDB | 25GB storage, 25 read/write units | Only writes during apply runs ✅ |
| EC2 t2.micro | 750 hours/month | Make sure to destroy after practice ✅ |

---

## 📊 Remote Backend — Key Comparison

| Feature | Local Backend | Remote Backend (S3) |
|---|---|---|
| State file location | Your machine | AWS S3 |
| Team collaboration | ❌ Not possible | ✅ Everyone shares same state |
| State locking | ❌ No locking | ✅ DynamoDB prevents conflicts |
| State history | ❌ No versioning | ✅ S3 versioning keeps history |
| Security | ❌ Plain text locally | ✅ Encrypted in S3 |
| Disaster recovery | ❌ Lost if machine crashes | ✅ Safe in cloud |

---

## ✅ Key Takeaways

- **Local backend** = state on your machine = risky for teams ❌
- **Remote backend (S3)** = state in cloud = safe, shared, team-friendly ✅
- **DynamoDB** = ensures only one person modifies state at a time ✅
- Always add `.gitignore` to prevent state files from being pushed to GitHub 🔐
- Always run `terraform destroy` after practice to avoid AWS charges 💸