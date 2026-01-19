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
First, I update apt and install some basic packages (git, curl, python3-pip). Everything else needs these.
- **Modules**: `apt`

### 2. Docker Role
This has to run first. Without Docker, I can't run any containers, so everything fails.
- Installs Docker Engine and Docker Compose
- Starts the Docker service
- Installs Python Docker library (Ansible needs this to run docker commands)
- **Modules**: `apt_key`, `apt_repository`, `apt`, `service`, `user`, `get_url`, `pip`, `docker_container`
- **Tags**: docker, setup

### 3. Clone Repo Role
I need to clone the code from GitHub before I can build anything. Can't build a Docker image without the Dockerfile and source code.
- Creates /opt/yolo directory
- Clones the repo from GitHub
- Creates .env file with the MongoDB connection string
- Sets up a directory for product images to be uploaded
- **Modules**: `file`, `git`, `copy`, `debug`
- **Tags**: clone, setup

### 4. MongoDB Role
The database has to be running before the backend starts. If the backend runs first, it can't connect and crashes.
- Creates a Docker network (yolo-network) so containers can communicate with each other
- Creates a volume (mongo-data) to keep database data even after container restarts
- Pulls the MongoDB image
- Runs the MongoDB container
- Waits for it to fully start up
- **Modules**: `docker_network`, `docker_volume`, `docker_image`, `docker_container`, `wait_for`, `docker_container_info`, `debug`
- **Tags**: mongodb, containers

### 5. Backend Role
The API needs to run before the frontend. The client can't talk to the backend if it's not there.
- Builds the backend Docker image from the Dockerfile
- Stops any old backend container that's running
- Starts a new backend container on port 5000
- Connects it to yolo-network
- Sets environment variables (MONGODB_URI, PORT)
- Mounts the volume for product images
- Waits for the API to actually be listening
- **Modules**: `docker_image`, `docker_container`, `wait_for`
- **Tags**: backend, containers

### 6. Client Role
The frontend goes last. Nothing depends on it being there, so I can put it at the end without breaking anything.
- Builds the React app using a multi-stage build (smaller image size)
- Stops any old client container
- Starts a new client container on port 3000 with nginx
- Connects it to yolo-network
- Waits for nginx to be ready
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
