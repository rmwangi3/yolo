# Explanation

## Playbook Execution Order

```
pre_tasks → docker → clone_repo → mongodb → backend → client → post_tasks
```

## Why This Order?

Each role depends on the ones before it. Breaking this order causes failures.

### 1. Pre-tasks
Updates apt and installs git, curl, python3-pip.
- **Modules**: `apt`

### 2. Docker Role
Installs Docker first since everything runs in containers.
- **What it does**: Installs Docker Engine, Docker Compose, Python Docker SDK
- **Modules**: `apt_key`, `apt_repository`, `apt`, `service`, `user`, `pip`, `docker_container`
- **Tags**: docker, setup

### 3. Clone Repo Role
Clones the code from GitHub. Needed before building images.
- **What it does**: Creates `/opt/yolo` directory, clones repo, creates .env file
- **Modules**: `file`, `git`, `copy`
- **Tags**: clone, setup

### 4. MongoDB Role
Database must run before backend tries to connect.
- **What it does**: Creates Docker network and volume, pulls MongoDB image, starts container
- **Modules**: `docker_network`, `docker_volume`, `docker_image`, `docker_container`, `wait_for`
- **Tags**: mongodb, containers

### 5. Backend Role
API must run before frontend makes requests.
- **What it does**: Builds backend image, starts container on port 5000, connects to MongoDB
- **Modules**: `docker_image`, `docker_container`, `wait_for`
- **Tags**: backend, containers

### 6. Client Role
Frontend goes last since nothing depends on it.
- **What it does**: Builds React app, starts nginx container on port 3000
- **Modules**: `docker_image`, `docker_container`, `wait_for`
- **Tags**: client, containers

### 7. Post-tasks
Shows URLs to access the app.

## Variables

Used `vars/main.yml` to store configuration like ports, container names, and MongoDB URI. Makes it easy to change settings in one place.

## Blocks and Tags

- **Blocks**: Groups related tasks (e.g., Docker installation steps)
- **Tags**: Run specific parts of playbook
  - `--tags setup` - just install Docker and clone repo
  - `--tags containers` - only deploy containers
  - `--skip-tags mongodb` - skip database

## Stage 2 - Terraform

Added Terraform in `Stage_two/` to automate VM provisioning. Terraform runs `vagrant up` via local-exec provisioner, which triggers the Ansible playbook.

Run with: `cd Stage_two && ansible-playbook playbook.yml -i ../inventory`

## Testing

1. `vagrant up`
2. Visit http://192.168.56.10:3000
3. Add a product
4. `vagrant reload`
5. Verify product persists (saved in MongoDB volume)

## Why Order Matters

- No Docker → can't run containers
- No repo → can't build images
- No MongoDB → backend crashes
- No backend → frontend shows errors
