# Stage 2: Terraform + Ansible

I used Terraform to provision stuff and Ansible to configure it all.

```
Stage_two/
├── terraform/          # Terraform files
│   ├── main.tf        # Main config
│   └── variables.tf   # Variables
├── playbook.yml       # The playbook
└── README.md          # Read me
```

## How to Run It

Just do this:
```bash
cd Stage_two
ansible-playbook playbook.yml -i ../inventory
```

What happens:
1. Terraform initializes
2. Vagrant VM gets created
3. Ansible configures everything
4. All containers start up

Or run Terraform manually:
```bash
cd Stage_two/terraform

terraform init
terraform plan
terraform apply
terraform destroy  # when done
```

## Access
Frontend: http://192.168.56.10:3000
Backend API: http://192.168.56.10:5000/api/products
