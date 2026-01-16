# YOLO E-commerce Platform - Complete Implementation Guide

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Quick Start](#quick-start)
5. [Detailed Setup](#detailed-setup)
6. [Ansible Implementation](#ansible-implementation)
7. [Testing & Verification](#testing--verification)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Usage](#advanced-usage)
10. [Documentation Index](#documentation-index)

---

## 🎯 Project Overview

This project implements a fully containerized MERN-stack e-commerce platform with complete Ansible automation for deployment. The infrastructure uses:

- **Frontend**: React application served by nginx
- **Backend**: Node.js/Express API
- **Database**: MongoDB with persistent storage
- **Orchestration**: Ansible for automated deployment
- **Virtualization**: Vagrant for VM provisioning
- **Containerization**: Docker for application isolation

### Key Features
- ✅ One-command deployment (`vagrant up`)
- ✅ Complete infrastructure automation with Ansible
- ✅ Product persistence across restarts
- ✅ Modular role-based architecture
- ✅ Comprehensive health checks and testing
- ✅ Production-ready configuration

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Host Machine (Your Computer)             │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          Vagrant VM (Ubuntu 20.04)                   │  │
│  │          IP: 192.168.56.10                           │  │
│  │                                                       │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │    Docker Network: yolo-network (bridge)       │ │  │
│  │  │                                                 │ │  │
│  │  │  ┌──────────────────────────────────────────┐ │ │  │
│  │  │  │  MongoDB Container (yolo-mongo)          │ │ │  │
│  │  │  │  Port: 27017 (internal)                  │ │ │  │
│  │  │  │  Volume: mongo-data (persistent)         │ │ │  │
│  │  │  └──────────────┬───────────────────────────┘ │ │  │
│  │  │                 │                               │ │  │
│  │  │  ┌──────────────▼───────────────────────────┐ │ │  │
│  │  │  │  Backend Container (yolo-backend)        │ │ │  │
│  │  │  │  Port: 5000                              │ │ │  │
│  │  │  │  API: /api/products                      │ │ │  │
│  │  │  │  Volume: ./backend/public/images         │ │ │  │
│  │  │  └──────────────┬───────────────────────────┘ │ │  │
│  │  │                 │                               │ │  │
│  │  │  ┌──────────────▼───────────────────────────┐ │ │  │
│  │  │  │  Client Container (yolo-client)          │ │ │  │
│  │  │  │  Port: 3000 → nginx:80                   │ │ │  │
│  │  │  │  Serves: React build (static files)      │ │ │  │
│  │  │  └──────────────────────────────────────────┘ │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Access URLs:                                               │
│  • Frontend:  http://192.168.56.10:3000                    │
│  • Backend:   http://192.168.56.10:5000/api/products       │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Prerequisites

### Required Software
Install the following on your host machine:

1. **Vagrant** (2.2.0+)
   ```bash
   # Ubuntu/Debian
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install vagrant
   
   # Verify
   vagrant --version
   ```

2. **VirtualBox** (6.1+)
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install virtualbox virtualbox-ext-pack
   
   # Verify
   VBoxManage --version
   ```

3. **Ansible** (2.9+)
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install ansible
   
   # Verify
   ansible --version
   ```

### System Requirements
- **CPU**: 2+ cores
- **RAM**: 4GB+ (2GB allocated to VM)
- **Disk**: 10GB+ free space
- **Network**: Internet connection for downloads

---

## 🚀 Quick Start

### Three-Step Deployment

1. **Clone the repository**
   ```bash
   git clone https://github.com/rmwangi3/yolo.git
   cd yolo
   ```

2. **Start the deployment**
   ```bash
   vagrant up
   ```
   
   This command will automatically:
   - Download Ubuntu 20.04 VM image (~600MB, first time only)
   - Create and configure the virtual machine
   - Run Ansible provisioning
   - Install Docker and dependencies
   - Clone application code
   - Build Docker images
   - Deploy all containers
   - Verify the deployment
   
   **Time**: 10-15 minutes (first run), 5-7 minutes (subsequent runs)

3. **Access the application**
   ```bash
   # Open in your browser
   http://192.168.56.10:3000
   ```

---

## 📝 Detailed Setup

### Project Structure
```
yolo/
├── Vagrantfile                    # VM configuration
├── ansible.cfg                    # Ansible settings
├── inventory                      # Host definitions
├── playbook.yml                  # Main orchestration playbook
├── Makefile                       # Helper commands
├── test_deployment.sh            # Automated testing script
│
├── vars/
│   └── main.yml                  # Configuration variables
│
├── roles/
│   ├── docker/                   # Docker installation
│   │   └── tasks/main.yml
│   ├── clone_repo/               # Code deployment
│   │   └── tasks/main.yml
│   ├── mongodb/                  # Database setup
│   │   └── tasks/main.yml
│   ├── backend/                  # API deployment
│   │   └── tasks/main.yml
│   └── client/                   # Frontend deployment
│       └── tasks/main.yml
│
├── backend/                       # Backend application code
│   ├── Dockerfile
│   ├── server.js
│   └── ...
│
├── client/                        # Frontend application code
│   ├── Dockerfile
│   ├── nginx.conf
│   └── ...
│
└── docs/                          # Documentation and resources
    ├── README.md                 # Main documentation
    ├── explanation.md            # Technical explanations
    ├── QUICKSTART.md            # Quick start guide
    ├── DEPLOYMENT_SUMMARY.md    # Implementation summary
    └── SUBMISSION_CHECKLIST.md  # Verification checklist
```

### Configuration Files

#### Vagrantfile
Defines the VM configuration:
- Ubuntu 20.04 base box (Jeff Geerling's trusted image)
- Network: Private IP 192.168.56.10
- Port forwarding: 3000 (frontend), 5000 (backend)
- Resources: 2 CPUs, 2GB RAM
- Ansible provisioning enabled

#### ansible.cfg
Ansible configuration:
- Inventory location
- SSH settings (uses Vagrant's insecure key)
- Logging configuration
- Performance optimizations

#### playbook.yml
Main orchestration playbook:
- Pre-tasks: System preparation
- Roles: Docker, clone_repo, mongodb, backend, client
- Post-tasks: Verification and info display
- Tags: For selective execution

#### vars/main.yml
Centralized variables:
- GitHub repository URL
- Docker configuration
- Container settings
- Port mappings
- Volume paths

---

## 🤖 Ansible Implementation

### Roles Overview

#### 1. Docker Role
**Purpose**: Install Docker Engine and Docker Compose

**Tasks**:
- Add Docker repository
- Install Docker CE
- Configure Docker users
- Install Docker Compose
- Install Python Docker SDK
- Verify installation

**Modules Used**: `apt_key`, `apt_repository`, `apt`, `service`, `user`, `get_url`, `pip`, `docker_container`

#### 2. Clone Repo Role
**Purpose**: Deploy application code from GitHub

**Tasks**:
- Create application directories
- Clone GitHub repository
- Create environment files
- Set permissions

**Modules Used**: `file`, `git`, `copy`

#### 3. MongoDB Role
**Purpose**: Deploy MongoDB container

**Tasks**:
- Create Docker network
- Create persistent volume
- Pull MongoDB image
- Start MongoDB container
- Verify deployment

**Modules Used**: `docker_network`, `docker_volume`, `docker_image`, `docker_container`, `docker_container_info`, `wait_for`

#### 4. Backend Role
**Purpose**: Build and deploy backend API

**Tasks**:
- Build backend Docker image
- Deploy backend container
- Configure environment variables
- Mount upload directory
- Test API endpoints

**Modules Used**: `docker_image`, `docker_image_info`, `docker_container`, `docker_container_info`, `wait_for`, `uri`

#### 5. Client Role
**Purpose**: Build and deploy frontend

**Tasks**:
- Build multi-stage client image
- Deploy client container
- Configure nginx
- Test frontend endpoint
- Verify complete stack

**Modules Used**: `docker_image`, `docker_image_info`, `docker_container`, `docker_container_info`, `wait_for`, `uri`, `command`

### Execution Flow

```
1. Pre-tasks
   └─> Update apt cache
   └─> Install system packages

2. Docker Role
   └─> Install Docker
   └─> Configure Docker
   └─> Verify installation

3. Clone Repo Role
   └─> Create directories
   └─> Clone from GitHub
   └─> Setup environment

4. MongoDB Role
   └─> Create network
   └─> Create volume
   └─> Deploy container

5. Backend Role
   └─> Build image
   └─> Deploy container
   └─> Test API

6. Client Role
   └─> Build image
   └─> Deploy container
   └─> Test frontend

7. Post-tasks
   └─> Display access info
```

---

## ✅ Testing & Verification

### Automated Testing

Run the automated test script:
```bash
./test_deployment.sh
```

This script tests:
- ✅ Ansible files exist
- ✅ Roles are properly structured
- ✅ Vagrant VM is running
- ✅ Docker is installed
- ✅ Containers are running
- ✅ Frontend is accessible
- ✅ Backend API responds
- ✅ Volumes and networks exist
- ✅ Documentation is complete

### Manual Testing

#### 1. Verify Containers
```bash
vagrant ssh -c "docker ps"
```

Expected output:
```
CONTAINER ID   IMAGE                  STATUS         PORTS                    NAMES
xxx            yolo-client:latest     Up X minutes   0.0.0.0:3000->80/tcp    yolo-client
xxx            yolo-backend:latest    Up X minutes   0.0.0.0:5000->5000/tcp  yolo-backend
xxx            mongo:5.0              Up X minutes   27017/tcp               yolo-mongo
```

#### 2. Test Backend API
```bash
curl http://192.168.56.10:5000/api/products
```

Expected: JSON array of products (empty `[]` or with products)

#### 3. Test Frontend
```bash
curl -I http://192.168.56.10:3000
```

Expected: `HTTP/1.1 200 OK`

#### 4. Test Add Product Functionality

1. Open browser: http://192.168.56.10:3000
2. Navigate to "Add Product"
3. Fill in:
   - Product name
   - Price
   - Description
   - Upload image
4. Submit form
5. Verify product appears in list

#### 5. Test Persistence
```bash
# Restart VM
vagrant reload

# Check if product still exists
curl http://192.168.56.10:5000/api/products

# Or check in browser
```

---

## 🔧 Troubleshooting

### Common Issues & Solutions

#### Issue: Vagrant up fails
```bash
# Solution 1: Check VirtualBox
VBoxManage --version

# Solution 2: Update Vagrant boxes
vagrant box update

# Solution 3: Destroy and recreate
vagrant destroy -f
vagrant up
```

#### Issue: Ansible provisioning fails
```bash
# Solution: Run with verbose output
vagrant provision -vvv

# Check logs
cat ansible.log
```

#### Issue: Can't access application
```bash
# Check VM status
vagrant status

# Check port forwarding
vagrant port

# Verify containers
vagrant ssh -c "docker ps"

# Check logs
vagrant ssh -c "docker logs yolo-backend"
vagrant ssh -c "docker logs yolo-client"
```

#### Issue: Backend can't connect to MongoDB
```bash
# Check MongoDB
vagrant ssh -c "docker logs yolo-mongo"

# Verify network
vagrant ssh -c "docker network inspect yolo-network"

# Check environment
vagrant ssh -c "docker exec yolo-backend env | grep MONGODB"
```

#### Issue: Frontend shows blank page
```bash
# Check nginx logs
vagrant ssh -c "docker logs yolo-client"

# Verify backend
curl http://192.168.56.10:5000/api/products

# Check nginx config
vagrant ssh -c "docker exec yolo-client cat /etc/nginx/conf.d/default.conf"
```

---

## 🎓 Advanced Usage

### Using Makefile Commands

```bash
# View all available commands
make help

# Vagrant operations
make up          # Start VM
make provision   # Re-run Ansible
make ssh         # SSH into VM
make halt        # Stop VM
make reload      # Restart VM
make destroy     # Remove VM

# Ansible operations
make playbook    # Run playbook manually
make ping        # Test connectivity
make docker-only # Install only Docker
make backend-only # Deploy only backend
make client-only # Deploy only frontend

# Utilities
make logs        # View all container logs
make ps          # Show running containers
make test        # Test application
make clean       # Clean up logs
```

### Selective Deployment with Tags

```bash
# Deploy only Docker
ansible-playbook playbook.yml --tags docker

# Deploy only containers (skip setup)
ansible-playbook playbook.yml --tags containers

# Deploy backend and client only
ansible-playbook playbook.yml --tags backend,client

# Run only tests
ansible-playbook playbook.yml --tags test

# Skip setup tasks
ansible-playbook playbook.yml --skip-tags setup
```

### Debugging Tips

```bash
# SSH into VM
vagrant ssh

# Check Docker
docker ps
docker logs <container-name>
docker network ls
docker volume ls

# Check application files
ls -la /opt/yolo
cat /opt/yolo/.env

# Check Ansible facts
ansible all -m setup -i inventory

# Test API from inside VM
curl localhost:5000/api/products
```

---

## 📚 Documentation Index

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Main project documentation |
| [explanation.md](explanation.md) | Technical implementation details |
| [QUICKSTART.md](QUICKSTART.md) | Quick start guide |
| [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md) | Implementation summary |
| [SUBMISSION_CHECKLIST.md](SUBMISSION_CHECKLIST.md) | Verification checklist |

---

## 🎯 Success Criteria

Your deployment is successful when:

1. ✅ `vagrant up` completes without errors
2. ✅ All three containers are running
3. ✅ Frontend loads at http://192.168.56.10:3000
4. ✅ Backend API responds at http://192.168.56.10:5000/api/products
5. ✅ You can add products via the UI
6. ✅ Products persist after VM restart
7. ✅ All tests in `test_deployment.sh` pass

---

## 📞 Support & Resources

- **Documentation**: Read all .md files in the project root
- **Logs**: Check `ansible.log` for Ansible execution details
- **Container Logs**: `vagrant ssh -c "docker logs <container-name>"`
- **GitHub Issues**: Report problems on the repository
- **Ansible Docs**: https://docs.ansible.com
- **Docker Docs**: https://docs.docker.com
- **Vagrant Docs**: https://www.vagrantup.com/docs

---

## 🎉 Conclusion

This project provides a complete, production-ready implementation of a containerized e-commerce platform with full automation. The modular architecture, comprehensive documentation, and automated testing make it easy to deploy, maintain, and extend.

**Happy Deploying!** 🚀
