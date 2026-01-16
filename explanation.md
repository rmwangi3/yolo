# Docker Implementation: Explanations & Practices

## 1. Base images
- Backend: `node:16-alpine` — small, secure base for Express and native modules.
- Client: multi-stage build — `node:16-alpine` (build) → `nginx:stable-alpine` (runtime). This produces optimized static assets served by a lightweight web server.
- Database: `mongo:5.0` — official MongoDB image for stability and compatibility.

Notes: Prefer pinning exact patch versions (e.g., `node:16.20.0-alpine`) for reproducible builds.

## 2. Dockerfile patterns
- Use `FROM` to select the base image.
- Use `WORKDIR` to set the working directory.
- Copy package manifests first and install dependencies (leverages Docker layer caching):
  - `COPY package*.json ./`
  - `RUN npm ci --only=production` (or `npm ci` in the build stage)
- Copy source: `COPY . .`
- Build step (client): `RUN npm run build` to produce production assets.
- Use multi-stage builds for client to produce a small runtime image.
- Use `EXPOSE` to document container ports (e.g., `5000` for backend, `80` for client). Publishing to the host is done via docker-compose or `docker run -p`.
- Prefer `CMD` or `ENTRYPOINT` as appropriate:
  - Backend: `CMD ["node", "server.js"]`
  - Client (nginx): `CMD ["nginx", "-g", "daemon off;"]`

## 3. Docker Compose: networking & ports
- Use a custom bridge network (e.g., `yolo-network`) so services can resolve each other by name (e.g., `mongo`).
- Example port mappings:
  - backend: `5000:5000`
  - client: `3000:80` (React/static app available at `http://localhost:3000`)

## 4. Data persistence
- Use a named volume for MongoDB:
  - `volumes: - mongo-data:/data/db`
- This ensures data persists across container restarts.

## 5. Git workflow
- Branching: create feature branches from `master` (e.g., `feature/dockerize`).
- Commit style: small, focused commits (e.g., `add backend Dockerfile`).
- Open pull requests for review before merging to `master`.

## 6. Running & debugging
- Build and run: `docker-compose up --build`
- Backend DB connection: set `MONGODB_URI=mongodb://mongo:27017/yolomy` so the backend resolves the DB service via Compose DNS.
- Logs:
  - `docker-compose logs -f backend`
  - `docker-compose logs -f mongo`
- Node version issues: check `engines` in `client/package.json` and adjust base image accordingly.

## 7. Image tagging & release practices
- Always use explicit tags (avoid `latest`), e.g., `rmwangi3/yolo-backend:1.0.0`.
- For CI/CD, use semantic versioning and include build metadata (or image digests) for traceability.

## 8. Security & reliability recommendations (additional)
- Run containers as a non-root user when possible.
- Add `HEALTHCHECK` for critical services (backend, database) and use container restart policies.
- Don’t store secrets in images; use environment variables, Docker secrets, or a secrets manager.
- Add resource limits in Compose (cpu/memory) for production deployments.

## 9. Development convenience
- Add a `.dockerignore` to exclude node_modules, logs, .git, and other unnecessary files.
- Consider `docker-compose.override.yml` for development-specific overrides (volumes, hot-reload).

## 10. DockerHub verification
- After pushing images, include screenshots on the repository or docs showing the repositories and tags, e.g.:
  - ![DockerHub backend 1.0.0](docs/dockerhub-backend-1.0.0.png)
  - ![DockerHub client 1.0.0](docs/dockerhub-client-1.0.0.png)

---

# Ansible Orchestration: Explanations & Practices

## 1. Overview
This Ansible implementation automates the deployment of the YOLO e-commerce application on a Vagrant-provisioned Ubuntu 20.04 VM. The playbook orchestrates the entire deployment process from Docker installation through application deployment and verification.

## 2. Playbook Structure & Execution Order

### Sequential Execution Rationale
The playbook executes roles in a specific order to ensure dependencies are satisfied:

1. **Pre-tasks** (System Preparation)
   - Updates apt cache and installs essential system packages
   - Ensures the system is ready for subsequent installations
   - Runs before any roles to guarantee a clean baseline

2. **docker role** (Infrastructure Foundation)
   - **Purpose**: Installs Docker Engine, Docker Compose, and Python Docker SDK
   - **Position Justification**: Must run first as all subsequent roles depend on Docker
   - **Key Modules Used**:
     - `apt_key` & `apt_repository`: Add Docker's official GPG key and repository
     - `apt`: Install Docker CE and related packages
     - `service`: Ensure Docker daemon is running and enabled
     - `user`: Add vagrant user to docker group for non-root access
     - `get_url`: Download Docker Compose standalone binary
     - `pip`: Install Python Docker SDK (required for Ansible docker_* modules)
     - `docker_container`: Run hello-world test to verify installation
   - **Blocks Used**: Groups related tasks for Docker prerequisites, installation, configuration, and verification
   - **Tags**: `docker`, `setup`, `docker-install`, `docker-service`, `docker-users`, `docker-compose`

3. **clone_repo role** (Application Source Code)
   - **Purpose**: Clones the YOLO application from GitHub and prepares the environment
   - **Position Justification**: Must run after Docker but before containers, as it provides source code needed for building images
   - **Key Modules Used**:
     - `file`: Create application directories with proper permissions
     - `git`: Clone repository from GitHub (supports force update)
     - `copy`: Create .env configuration file with environment variables
   - **Tags**: `clone`, `setup`, `repo-setup`, `repo-clone`, `repo-configuration`

4. **mongodb role** (Database Layer)
   - **Purpose**: Sets up MongoDB container with persistent storage
   - **Position Justification**: Backend depends on MongoDB, so it must start before the backend
   - **Key Modules Used**:
     - `docker_network`: Create custom bridge network for inter-container communication
     - `docker_volume`: Create named volume for MongoDB data persistence
     - `docker_image`: Pull MongoDB 5.0 image from Docker Hub
     - `docker_container`: Run MongoDB with health checks and proper networking
     - `docker_container_info`: Verify container status
     - `wait_for`: Pause to allow MongoDB to initialize
   - **Blocks Used**: Groups container deployment, waiting, and verification tasks
   - **Tags**: `mongodb`, `database`, `containers`, `mongodb-network`, `mongodb-volume`

5. **backend role** (Application API Layer)
   - **Purpose**: Builds and deploys Node.js backend container
   - **Position Justification**: Depends on MongoDB being available; frontend depends on backend API
   - **Key Modules Used**:
     - `docker_image`: Build backend image from Dockerfile with build context
     - `docker_image_info`: Verify image creation
     - `docker_container`: Deploy backend with environment variables and volume mounts
     - `wait_for`: Wait for backend port to be available
     - `uri`: Test API endpoint functionality
   - **Blocks Used**: Separates image building from container deployment for clarity
   - **Tags**: `backend`, `api`, `containers`, `backend-build`, `backend-deploy`, `backend-test`

6. **client role** (Frontend Presentation Layer)
   - **Purpose**: Builds and deploys React frontend served by nginx
   - **Position Justification**: Runs last as it depends on backend API being available
   - **Key Modules Used**:
     - `docker_image`: Build multi-stage client image (Node build → nginx runtime)
     - `docker_container`: Deploy frontend container with nginx
     - `wait_for`: Wait for frontend port availability
     - `uri`: Test frontend accessibility
     - `command`: List all running containers for final verification
   - **Blocks Used**: Separates build, deploy, and stack verification phases
   - **Tags**: `client`, `frontend`, `containers`, `client-build`, `client-deploy`, `client-test`

7. **Post-tasks** (Deployment Verification)
   - Displays access information for the deployed application
   - Provides URLs for testing frontend and backend
   - Runs after all roles complete successfully

## 3. Variables & Configuration Management

### Variable File (`vars/main.yml`)
Centralizes all configuration parameters for easy modification:
- **Application settings**: GitHub repository, branch, deployment paths
- **Docker configuration**: Compose version, network settings, volume names
- **Service-specific settings**: Container names, ports, image tags
- **Environment variables**: MongoDB URI, backend port configuration

**Benefits**:
- Single source of truth for configuration
- Easy environment-specific customization
- Separation of code from configuration
- Simplified maintenance and updates

## 4. Blocks & Error Handling

### Block Usage
Blocks group related tasks logically and enable:
- **Error handling**: Can add `rescue` and `always` sections for robustness
- **Conditional execution**: Apply conditions to entire task groups
- **Improved readability**: Clear functional separation
- **Tag application**: Apply tags to logical units of work

**Example**: The Docker role uses blocks to separate:
- Prerequisites installation
- Docker engine installation
- User configuration
- Verification tasks

## 5. Tags for Selective Execution

### Tag Strategy
Tags enable targeted playbook execution:
- **Functional tags**: `setup`, `docker`, `mongodb`, `backend`, `client`
- **Action tags**: `build`, `deploy`, `test`, `verify`
- **Component tags**: `containers`, `network`, `volume`, `image`

**Usage Examples**:
```bash
# Run only Docker installation
ansible-playbook playbook.yml --tags docker

# Skip setup and run only container deployment
ansible-playbook playbook.yml --skip-tags setup

# Run only backend deployment
ansible-playbook playbook.yml --tags backend

# Test endpoints without full deployment
ansible-playbook playbook.yml --tags test
```

## 6. Idempotency & Best Practices

### Idempotent Design
- All tasks can be run multiple times safely
- Docker modules handle existing resources gracefully
- Git module supports force updates
- Container tasks stop existing containers before redeployment

### Best Practices Implemented
1. **Variable files**: Centralized configuration management
2. **Roles**: Modular, reusable components
3. **Blocks**: Logical task grouping
4. **Tags**: Flexible execution control
5. **Health checks**: Container readiness verification
6. **Wait conditions**: Service availability confirmation
7. **Testing**: Automated endpoint validation
8. **Logging**: Comprehensive status reporting

## 7. Networking & Persistence

### Docker Networking
- Custom bridge network (`yolo-network`) enables:
  - DNS-based service discovery (containers resolve by name)
  - Isolation from other Docker networks
  - Controlled inter-container communication

### Data Persistence
- **MongoDB volume**: Named volume ensures database persistence
- **Image uploads**: Bind mount preserves uploaded product images
- **Environment files**: Persistent configuration across deployments

## 8. Vagrant Integration

### Vagrant Configuration
- Uses Jeff Geerling's Ubuntu 20.04 box (trusted, well-maintained)
- Configures port forwarding for application access
- Sets up private network for Ansible connectivity
- Disables SSH key insertion for simplified authentication
- Automatically provisions with Ansible on `vagrant up`

### Simplified Authentication
- Uses Vagrant's insecure private key (acceptable for development)
- No certificate or key management required
- Facilitates easy marking and assessment

## 9. Testing & Verification

### Automated Testing
The playbook includes multiple verification steps:
1. **Docker verification**: Hello-world test container
2. **MongoDB verification**: Container status check
3. **Backend API test**: HTTP GET to products endpoint
4. **Frontend test**: HTTP GET to main page
5. **Stack verification**: Lists all running containers

### Manual Testing
After deployment, test the "Add Product" functionality:
1. Navigate to http://192.168.56.10:3000
2. Add a product through the UI
3. Verify product appears in the list
4. Run `vagrant reload` to restart VM
5. Verify product persistence after restart

## 10. Future Enhancements

### Potential Improvements
- **Stage 2 Integration**: Add Terraform for infrastructure provisioning
- **Secrets management**: Use Ansible Vault for sensitive data
- **CI/CD integration**: Add GitHub Actions workflow
- **Monitoring**: Add Prometheus/Grafana for observability
- **Backup automation**: Scheduled MongoDB backups
- **SSL/TLS**: Add HTTPS support with Let's Encrypt
- **Load balancing**: Add nginx reverse proxy for scalability

## 11. Troubleshooting Guide

### Common Issues & Solutions

**Issue**: Docker installation fails
- **Solution**: Check internet connectivity; verify Ubuntu version compatibility

**Issue**: MongoDB container won't start
- **Solution**: Check volume permissions; verify port 27017 is available

**Issue**: Backend can't connect to MongoDB
- **Solution**: Verify MongoDB container is running; check environment variables

**Issue**: Frontend shows blank page
- **Solution**: Check backend API availability; verify nginx configuration

**Issue**: Ansible can't connect to VM
- **Solution**: Verify VM is running (`vagrant status`); check SSH configuration

### Debug Commands
```bash
# Check Ansible connectivity
ansible all -m ping -i inventory

# Run playbook in verbose mode
ansible-playbook playbook.yml -vvv

# Check Docker status in VM
vagrant ssh -c "docker ps"

# View container logs
vagrant ssh -c "docker logs yolo-backend"

# Test backend API
curl http://192.168.56.10:5000/api/products
```