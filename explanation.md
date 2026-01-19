# Explanation

I'm going to explain how I structured the playbook and why the order matters.

## How the Playbook Runs

Here's the order everything happens:

```
pre_tasks → docker → clone_repo → mongodb → backend → client → post_tasks
```

## Why the Order Matters

Each role depends on the ones before it. If I change the order, stuff breaks. Let me explain why.

## What Each Role Does

### 1. Pre-tasks
First thing I do is update apt and install git, curl, python3-pip. Can't do anything without these.
- **Modules**: `apt`

### 2. Docker Role
This goes first obviously. No Docker = no containers = nothing works.
- Install Docker Engine and Docker Compose
- Start Docker daemon
- Install Python Docker library (Ansible uses this to manage containers)
- **Modules**: `apt_key`, `apt_repository`, `apt`, `service`, `user`, `get_url`, `pip`, `docker_container`
- **Tags**: docker, setup

### 3. Clone Repo Role
Gotta get the code from GitHub first. I need the Dockerfiles and everything before I can build anything.
- Create /opt/yolo directory
- Clone the repo
- Make the .env file with MongoDB settings
- Set up folder for product images
- **Modules**: `file`, `git`, `copy`, `debug`
- **Tags**: clone, setup

### 4. MongoDB Role
Database has to be up before backend tries to connect or it breaks immediately.
- Create Docker network (yolo-network) so containers can talk to each other
- Create volume (mongo-data) to save database stuff even after container dies
- Pull MongoDB image
- Start MongoDB container
- Wait for it to actually be ready
- **Modules**: `docker_network`, `docker_volume`, `docker_image`, `docker_container`, `wait_for`, `docker_container_info`, `debug`
- **Tags**: mongodb, containers

### 5. Backend Role
Backend needs to run before the frontend so they can actually talk to each other.
- Build backend Docker image
- Kill old backend container if it's running
- Start new backend on port 5000
- Connect to yolo-network
- Set environment variables (MONGODB_URI, PORT)
- Mount the images volume
- Check that port 5000 is listening
- **Modules**: `docker_image`, `docker_container`, `wait_for`
- **Tags**: backend, containers

### 6. Client Role
Frontend is last because nothing else depends on it. Can put it anywhere really.
- Build React frontend with multi-stage Dockerfile (saves space)
- Stop old client container
- Start new client on port 3000 with nginx
- Connect to yolo-network
- Wait for nginx to be ready
- **Modules**: `docker_image`, `docker_container`, `wait_for`
- **Tags**: client, containers

### 7. Post-tasks
Just displays the URLs where you can access the app. Useful for testing.

## Variables

I put all the configuration in `vars/main.yml`. This way if I need to change something like a port number, I only have to change it in one place instead of looking through all the roles.

## Blocks and Tags

I used blocks in the docker role to group related tasks together. For example, all the Docker Compose installation steps are in one block.

Tags let me run specific parts of the playbook:
- `--tags setup` - just install Docker and clone the repo
- `--tags containers` - only deploy containers (assuming Docker is already installed)
- `--skip-tags mongodb` - skip the database setup

## Stage 2 - Terraform

For Stage 2, I added Terraform to automate the VM creation. Terraform uses `local-exec` to run `vagrant up`, which then triggers the Ansible playbook.

To run it: `cd Stage_two && ansible-playbook playbook.yml -i ../inventory`

The terraform.tfstate file is in the repo (as required) but I excluded the backup state file like the assignment asked.

## Testing

To check if everything works:

1. Run `vagrant up`
2. Go to http://192.168.56.10:3000
3. Add a product with name, price, etc
4. Run `vagrant reload` to restart everything
5. Check if the product is still there

The product should stay because MongoDB data is saved in a volume that doesn't get deleted when the container stops.

## Why Order Matters

- No Docker → nothing can run
- No repo code → can't build images
- No MongoDB → backend crashes immediately
- No backend → frontend has nothing to connect to

That's why I had to order it this way.
