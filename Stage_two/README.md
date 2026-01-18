# Stage 2: Terraform + Ansible Infrastructure

Stage 2 implements Infrastructure as Code using **Terraform** for resource provisioning and **Ansible** for application deployment.

## Structure

```
terraform/        # Terraform IaC files
playbook.yml      # Ansible playbook
inventory         # Ansible inventory
Vagrantfile       # VM configuration
```

## Prerequisites

- Vagrant (>= 2.2.0)
- VirtualBox (>= 6.0)
- Terraform (>= 1.0)
- Ansible (>= 2.9)

## Deployment

### Option 1: Using Script
```bash
./deploy.sh
```

### Option 2: Manual Steps
```bash
# Start VM
vagrant up

# Deploy with Ansible
ansible-playbook -i inventory playbook.yml

# Verify
vagrant ssh -c "docker ps"
```

### Option 3: Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

## Access Application

- Frontend: http://localhost:3000
- Backend: http://localhost:5000
- MongoDB: localhost:27017

## Cleanup

```bash
vagrant destroy -f
# or
terraform destroy
```

For full automation, use the deployment script instead of `terraform apply`.

## Manual Deployment (Alternative)

If you prefer to run steps separately:

```bash
# 1. Start Vagrant VM
vagrant up

# 2. Wait for VM to be ready
sleep 30

# 3. Run Ansible playbook
ansible-playbook -i inventory playbook.yml

# 4. Verify deployment
vagrant ssh -c "docker ps"
```

## Configuration

### Terraform Variables

Edit `terraform/variables.tf` to customize:

- `vagrant_box`: Vagrant box name (default: geerlingguy/ubuntu2004)
- `vm_memory`: RAM allocation (default: 2048 MB)
- `vm_cpus`: CPU cores (default: 2)
- `app_port`: Frontend port (default: 3000)
- `backend_port`: Backend port (default: 5000)
- `mongodb_port`: Database port (default: 27017)

### Ansible Roles

The playbook uses the following roles from Stage 1:

- **docker**: Installs Docker and Docker Compose
- **clone_repo**: Clones application code
- **mongodb**: Deploys MongoDB container
- **backend**: Deploys Node.js backend container
- **client**: Deploys React frontend container

## Testing

### Verify Containers

```bash
vagrant ssh
docker ps
```

Expected output: 3 running containers (mongodb, backend, client)

### Test Application

```bash
# Test frontend
curl http://localhost:3000

# Test backend API
curl http://localhost:5000/api/products

# Add a product via the web interface
```

## Cleanup

### Destroy Infrastructure

```bash
cd terraform
terraform destroy
```

### Stop Vagrant VM

```bash
vagrant halt
```

### Remove VM Completely

```bash
vagrant destroy
```

## Troubleshooting

### Terraform Issues

**Problem**: `Error: Failed to execute local command`
```bash
# Solution: Ensure Vagrant is installed and in PATH
vagrant --version
```

**Problem**: Port conflicts
```bash
# Solution: Check for processes using ports 3000, 5000, 27017
lsof -i :3000
lsof -i :5000
lsof -i :27017
```

### Ansible Issues

**Problem**: `SSH connection failed`
```bash
# Solution: Wait for VM to fully boot
vagrant up
sleep 30
ansible-playbook -i inventory playbook.yml
```

**Problem**: `Permission denied`
```bash
# Solution: Verify SSH key permissions
chmod 600 .vagrant/machines/default/virtualbox/private_key
```

### Container Issues

**Problem**: Containers not starting
```bash
vagrant ssh
docker logs <container_name>
```

## Key Differences from Stage 1

| Aspect | Stage 1 | Stage 2 |
|--------|---------|---------|
| **Provisioning** | Manual Vagrant | Terraform-managed Vagrant |
| **Orchestration** | Ansible only | Terraform + Ansible |
| **IaC** | Partial | Full Infrastructure as Code |
| **State Management** | None | Terraform state |
| **Reproducibility** | Manual steps | Single `terraform apply` |

## Variables File

Variables are shared with Stage 1 via `../vars/main.yml`:

```yaml
repo_url: "https://github.com/your-repo/yolo.git"
app_dir: "/opt/yolo"
docker_compose_version: "1.29.2"
```

## CI/CD Integration

This setup is CI/CD ready:

```bash
# Automated pipeline example
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

## Stage 2 Compliance Checklist

- ✅ Checked out to `Stage_two` branch
- ✅ Created `Stage_two/` directory in root
- ✅ Terraform configuration for provisioning
- ✅ Ansible playbook for configuration
- ✅ Vagrant VM provisioning
- ✅ Docker containerization
- ✅ Similar stack to Stage 1
- ✅ Documentation and README

## Support

For issues or questions:
1. Check logs: `vagrant ssh` → `docker logs <container>`
2. Verify network: `vagrant ssh` → `docker network ls`
3. Review Ansible output for errors
4. Check Terraform state: `terraform show`

## License

This is an educational project for the Moringa School DevOps IP.
