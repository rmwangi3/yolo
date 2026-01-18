# Stage 2: Terraform + Ansible Integration

## Overview
This stage combines Terraform for infrastructure provisioning with Ansible for configuration management.

## Structure
```
Stage_two/
├── terraform/          # Terraform configurations
│   ├── main.tf        # Main Terraform config
│   └── variables.tf   # Variable definitions
├── playbook.yml       # Integrated playbook
└── README.md          # This file
```

## Usage

### One-Command Deployment
```bash
cd Stage_two
ansible-playbook playbook.yml -i ../inventory
```

This will:
1. Initialize Terraform
2. Provision infrastructure (Vagrant VM)
3. Configure the VM with Ansible
4. Deploy all containers

### Manual Terraform Operations
```bash
cd Stage_two/terraform

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Destroy
terraform destroy
```

## Access
- Frontend: http://192.168.56.10:3000
- Backend: http://192.168.56.10:5000/api/products
