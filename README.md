# Yolo E-commerce - Ansible & Terraform Deployment

Containerized MERN e-commerce application with Docker, Ansible, and Terraform.

## Stage 1: Ansible Deployment

**Prerequisites**: Vagrant, VirtualBox, Ansible

```bash
git clone https://github.com/rmwangi3/yolo.git
cd yolo
vagrant up
```

**Access**:
- Frontend: http://192.168.56.10:3000
- Backend: http://192.168.56.10:5000/api/products

## Stage 2: Terraform + Ansible Integration

```bash
cd Stage_two
ansible-playbook playbook.yml -i ../inventory
```

This integrates Terraform for infrastructure provisioning with Ansible for configuration.

## Manual Deployment

```bash
# Docker Compose
docker-compose up --build

# Ansible only
ansible-playbook -i inventory playbook.yml

# With tags
ansible-playbook -i inventory playbook.yml --tags docker,mongodb

# Terraform only (Stage 2)
cd Stage_two/terraform && terraform init && terraform apply
```

## Vagrant Commands

```bash
vagrant up          # Start VM
vagrant ssh         # SSH into VM
vagrant halt        # Stop VM
vagrant destroy     # Remove VM
vagrant provision   # Re-run Ansible
```

---

## Troubleshooting VirtualBox Issues

If you encounter VirtualBox errors (guru meditation, locked VM), use these alternatives:

### Option 1: Docker Compose (Recommended)
```bash
docker-compose up -d
```
Access at http://localhost:3000 and http://localhost:5000

### Option 2: Ansible on Localhost
```bash
ansible-playbook -i inventory_local playbook.yml --skip-tags docker -e "ansible_become_pass=YOUR_PASSWORD"
```

### Option 3: Fix VirtualBox
```bash
# Kill stuck processes
killall VBoxHeadless VBoxManage VirtualBox VirtualBoxVM

# Destroy and recreate
vagrant destroy -f && vagrant up

# If still failing, restart Docker service
sudo systemctl restart docker
```

---

## Persistence

- MongoDB data is persisted to a named Docker volume `mongo-data` (configured in `docker-compose.yml` at `/data/db`). Added products will persist across container restarts and VM reboots.
- Uploaded product images are stored in `backend/public/images`. The `docker-compose.yml` includes a bind mount so uploaded images persist on the host at `./backend/public/images`.

---

## Important Files

---

## Important Files

- `Vagrantfile` — Vagrant configuration for Ubuntu 20.04 VM provisioning
- `playbook.yml` — Main Ansible playbook orchestrating the deployment
- `ansible.cfg` — Ansible configuration settings
- `inventory` — Ansible inventory defining target hosts
- `vars/main.yml` — Centralized variables for configuration
- `roles/` — Ansible roles for modular deployment (docker, clone_repo, mongodb, backend, client)
- `docker-compose.yml` — Docker Compose configuration (defines `mongo`, `backend`, and `client` services)
- `backend/Dockerfile` — Node-based backend image
- `client/Dockerfile` — Multi-stage build (Node => nginx) to serve the frontend
- `explanation.md` — Comprehensive rationale for Docker, Ansible, roles, modules, and execution order

---

## Testing the Application

### Add Product Functionality Test

1. **Access the frontend** in your browser:
   - http://192.168.56.10:3000

2. **Add a product**:
   - Navigate to the "Add Product" section
   - Fill in product details (name, price, description)
   - Upload a product image
   - Submit the form

3. **Verify the product appears** in the product list

4. **Test persistence**:
   ```bash
   # Restart the VM
   vagrant reload
   
   # Or stop and start containers
   vagrant ssh
   docker restart yolo-backend yolo-client yolo-mongo
   exit
   ```

5. **Verify the product still exists** after restart

### API Testing

```bash
# Test backend API directly
curl http://192.168.56.10:5000/api/products

# Add a product via API
curl -X POST http://192.168.56.10:5000/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Product","price":99.99,"description":"Test description"}'
```

---

## Troubleshooting

### Common Issues

**Issue**: Vagrant VM fails to start
```bash
# Check VirtualBox installation
VBoxManage --version

# Verify Vagrant installation
vagrant version

# Check VM status
vagrant status
```

**Issue**: Ansible provisioning fails
```bash
# Run playbook with verbose output
vagrant provision --provision-with ansible -vvv

# Or run manually
ansible-playbook -i inventory playbook.yml -vvv
```

**Issue**: Cannot access application in browser
```bash
# Check if VM is running
vagrant status

# Verify port forwarding
vagrant port

# SSH into VM and check containers
vagrant ssh
docker ps
docker logs yolo-backend
docker logs yolo-client
```

**Issue**: Backend can't connect to MongoDB
```bash
vagrant ssh
# Check MongoDB container
docker logs yolo-mongo

# Verify network
docker network inspect yolo-network

# Check environment variables
docker exec yolo-backend env | grep MONGODB
```

**Issue**: Frontend shows blank page
```bash
vagrant ssh
# Check nginx logs
docker logs yolo-client

# Verify backend is responding
curl http://localhost:5000/api/products
```

### Debug Commands

```bash
# Check all containers
vagrant ssh -c "docker ps -a"

# View playbook execution log
cat ansible.log

# Test Ansible connectivity
ansible all -m ping -i inventory

# Check Docker network
vagrant ssh -c "docker network ls"

# Check volumes
vagrant ssh -c "docker volume ls"

# Restart specific service
vagrant ssh -c "docker restart yolo-backend"
```

### Clean Rebuild

If you need to start fresh:

```bash
# Destroy VM and rebuild
vagrant destroy -f
vagrant up

# Or just re-provision
vagrant reload --provision
```

---

## Notes and Troubleshooting (Docker Compose Method)

---

## Notes and Troubleshooting (Docker Compose Method)

When using Docker Compose directly (without Ansible):

- If the backend fails to connect to MongoDB, ensure `.env` contains `MONGODB_URI=mongodb://mongo:27017/yolomy` and that you started the compose stack.
- To inspect backend logs:

```bash
docker-compose logs -f backend
```

- To test persistence manually:
	1. Add a product through the UI.
	2. Stop containers: `docker-compose down`.
	3. Start containers: `docker-compose up`.
	4. Verify the product still exists via the UI or `curl http://localhost:5000/api/products`.

---

## Publishing Images & DockerHub

---

## Publishing Images & DockerHub

- When publishing images to DockerHub, use semantic tags (e.g., `rmwangi3/yolo-backend:1.0.0`) so versions are easy to identify.
- The Ansible playbook builds images with proper tags automatically.

### Manual Push to DockerHub

```bash
# Login to DockerHub
docker login

# Tag images
docker tag yolo-backend:latest rmwangi3/yolo-backend:1.0.0
docker tag yolo-client:latest rmwangi3/yolo-client:1.0.0

# Push images
docker push rmwangi3/yolo-backend:1.0.0
docker push rmwangi3/yolo-client:1.0.0
```

---

## DockerHub Images (Screenshots)

Once you build and push your images to DockerHub, add screenshots of the DockerHub repository page showing the image tags.

- Place your screenshot files in `docs/` (for example `docs/dockerhub-backend.png` and `docs/dockerhub-client.png`).
- Then add them to the repo and push:

```bash
git add docs/dockerhub-backend.png docs/dockerhub-client.png
git commit -m "Add DockerHub screenshots"
git push origin master
```

Backend DockerHub image:

![Backend DockerHub screenshot](docs/dockerhub-backend.png)

Client DockerHub image:

![Client DockerHub screenshot](docs/dockerhub-client.png)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Host Machine                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Vagrant VM (Ubuntu 20.04)               │  │
│  │                                                       │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │         Docker Network (yolo-network)          │ │  │
│  │  │                                                 │ │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌─────────────┐ │ │  │
│  │  │  │ MongoDB  │  │ Backend  │  │   Client    │ │ │  │
│  │  │  │  :27017  │←─│  :5000   │←─│  nginx:80   │ │ │  │
│  │  │  └─────┬────┘  └──────────┘  └─────────────┘ │ │  │
│  │  │        │                                       │ │  │
│  │  │        ↓                                       │ │  │
│  │  │  ┌──────────┐                                 │ │  │
│  │  │  │  Volume  │                                 │ │  │
│  │  │  │mongo-data│                                 │ │  │
│  │  │  └──────────┘                                 │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  │                                                       │  │
│  │  Port Forwarding:                                    │  │
│  │  - 3000:80 (Frontend)                                │  │
│  │  - 5000:5000 (Backend API)                           │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Access via:                                                │
│  - http://192.168.56.10:3000 (Frontend)                    │
│  - http://192.168.56.10:5000/api/products (Backend)        │
└─────────────────────────────────────────────────────────────┘
```

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License.

---

## Contact / Support

For issues or questions:
- Open an issue on GitHub
- Check the `explanation.md` file for detailed implementation details
- Review the Ansible logs in `ansible.log`

---

## Acknowledgments

- Jeff Geerling for the Ubuntu 20.04 Vagrant box
- Docker and Ansible communities for excellent documentation
- MERN stack developers for the technology foundation


