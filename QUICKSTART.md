# YOLO E-commerce - Quick Start Guide

This guide will help you get the YOLO e-commerce application running using Ansible automation.

## Prerequisites

Ensure you have installed:
- **Vagrant** (2.2.0+): https://www.vagrantup.com/downloads
- **VirtualBox** (6.1+): https://www.virtualbox.org/wiki/Downloads
- **Ansible** (2.9+): https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

## Quick Start (3 Steps)

### Step 1: Clone the Repository
```bash
git clone https://github.com/rmwangi3/yolo.git
cd yolo
```

### Step 2: Start the VM and Deploy
```bash
vagrant up
```

This single command will:
- ✅ Download Ubuntu 20.04 VM image
- ✅ Create and configure the virtual machine
- ✅ Run Ansible provisioning automatically
- ✅ Install Docker and all dependencies
- ✅ Clone application code
- ✅ Build Docker images
- ✅ Start all containers (MongoDB, Backend, Frontend)
- ✅ Verify the deployment

**Time**: First run takes 10-15 minutes (includes downloading VM image and building containers)

### Step 3: Access the Application
Open your browser and navigate to:
- **Frontend**: http://192.168.56.10:3000 or http://localhost:3000
- **Backend API**: http://192.168.56.10:5000/api/products

## Testing Product Persistence

1. **Add a Product**:
   - Go to http://192.168.56.10:3000
   - Navigate to "Add Product"
   - Fill in the product details
   - Upload an image
   - Submit

2. **Test Persistence**:
   ```bash
   vagrant reload
   ```

3. **Verify**: The product should still be there after VM restart!

## Common Commands

```bash
# Check VM status
vagrant status

# SSH into the VM
vagrant ssh

# Re-run Ansible provisioning
vagrant provision

# Restart the VM
vagrant reload

# Stop the VM
vagrant halt

# Destroy the VM (clean slate)
vagrant destroy -f

# View container logs
vagrant ssh -c "docker logs yolo-backend"
vagrant ssh -c "docker logs yolo-client"
```

## Selective Deployment with Tags

Run specific parts of the playbook:

```bash
# Only install Docker
ansible-playbook -i inventory playbook.yml --tags docker

# Only deploy backend
ansible-playbook -i inventory playbook.yml --tags backend

# Deploy backend and frontend only
ansible-playbook -i inventory playbook.yml --tags backend,client

# Run tests only
ansible-playbook -i inventory playbook.yml --tags test
```

## Troubleshooting

### VM Won't Start
```bash
# Check VirtualBox
VBoxManage --version

# Check Vagrant
vagrant version

# Try with verbose output
vagrant up --debug
```

### Can't Access Application
```bash
# Check if containers are running
vagrant ssh -c "docker ps"

# Check backend logs
vagrant ssh -c "docker logs yolo-backend"

# Check if ports are forwarded
vagrant port
```

### Ansible Fails
```bash
# Run with verbose output
vagrant provision -vvv

# Check ansible log
cat ansible.log
```

### Start Fresh
```bash
vagrant destroy -f
vagrant up
```

## Project Structure

```
yolo/
├── Vagrantfile           # VM configuration
├── playbook.yml         # Main Ansible playbook
├── ansible.cfg          # Ansible settings
├── inventory            # Host definitions
├── vars/
│   └── main.yml        # Configuration variables
└── roles/
    ├── docker/         # Docker installation
    ├── clone_repo/     # Code deployment
    ├── mongodb/        # Database setup
    ├── backend/        # API deployment
    └── client/         # Frontend deployment
```

## What Gets Deployed?

1. **MongoDB Container** (`yolo-mongo`)
   - Port: 27017 (internal)
   - Volume: mongo-data (persistent)
   - Network: yolo-network

2. **Backend Container** (`yolo-backend`)
   - Port: 5000
   - Image: Built from `backend/Dockerfile`
   - API: http://192.168.56.10:5000/api/products

3. **Client Container** (`yolo-client`)
   - Port: 3000 (mapped to nginx port 80)
   - Image: Built from `client/Dockerfile`
   - Frontend: http://192.168.56.10:3000

## Next Steps

- Read [explanation.md](explanation.md) for detailed architecture information
- Read [README.md](README.md) for complete documentation
- Test the "Add Product" functionality
- Try selective deployments with tags
- Experiment with the Ansible roles

## Support

If you encounter issues:
1. Check the [Troubleshooting](#troubleshooting) section above
2. Review `ansible.log` for detailed logs
3. Check container logs: `vagrant ssh -c "docker logs <container-name>"`
4. Open an issue on GitHub with error details

## Success Indicators

You'll know the deployment succeeded when:
- ✅ `vagrant up` completes without errors
- ✅ You see "YOLO E-commerce Application Deployment Complete!" message
- ✅ Frontend loads at http://192.168.56.10:3000
- ✅ Backend API responds at http://192.168.56.10:5000/api/products
- ✅ You can add products and they persist after VM restart

Happy deploying! 🚀
