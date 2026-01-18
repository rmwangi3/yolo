# Stage 2: Terraform + Ansible Integration

## Overview
This stage combines Terraform for infrastructure provisioning with Ansible for configuration management.

## Structure
```
Stage_two/
├── terraform/          # Terraform Integrations
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

From this, we expect that:
1. Terraform will be initialized
2. Provisioned infrastructure (Vagrant VM)
3. The VM with Ansible will be configured
4. All containers will be deployed

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
