# Day 5 — Terraform Workspaces 🏗️

---

## What is a Terraform Workspace? 🤔

A workspace is an **isolated environment** with its own separate state file — using the **same code**.

By default every project has a workspace called **default**.

---

## The Problem 😤

You need Dev, Staging and Prod environments. Without workspaces you end up **copy-pasting** the same code into 3 folders. Now every change needs to be updated in 3 places. Easy to miss one and cause bugs.

---

## The Solution ✅

Write the code **once**. Just switch the workspace.

Same code → Different workspace → Different environment. That's it.

---

## Commands 🛠️

| Command | What it does |
|---|---|
| `terraform workspace list` | See all workspaces |
| `terraform workspace new <name>` | Create a new workspace |
| `terraform workspace select <name>` | Switch to a workspace |
| `terraform workspace show` | See which workspace you are currently in |
| `terraform workspace delete <name>` | Delete a workspace |

---

## Real World Example 🌍

A company needs 3 environments for their app —

🧑‍💻 **Dev** → Developer tests code → small instance → t2.micro

🧪 **Staging** → QA runs tests → medium instance → t2.medium

🚀 **Prod** → Live users → large instance → t2.large

Same Terraform code. Just switch workspace. Done.

---

## When to Use ✅

- Environments are similar to each other
- Small to medium projects
- You want no code duplication

## When NOT to Use ❌

- Environments are very different from each other
- Large teams where wrong workspace = disaster
- You need separate AWS accounts per environment

---

## Golden Rule 🥇

> Always run `terraform workspace show` before `terraform apply` — so you never accidentally destroy production!

---