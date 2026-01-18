# Implementation Notes

## Docker Setup

I used these base images:
- Backend: `node:16-alpine` - keeps it lightweight
- Client: Multi-stage build with `node:16-alpine` for building, then `nginx:stable-alpine` for serving
- Database: `mongo:5.0` - standard MongoDB image

The Dockerfiles follow some common patterns - copy package files first (for better caching), install dependencies, then copy source code. For the client, I'm doing a multi-stage build which makes the final image much smaller since it only includes the built files and nginx.

For networking, everything runs on a custom bridge network called `yolo-network`. This lets containers talk to each other by name. The backend connects to MongoDB using `mongodb://mongo:27017/yolomy` - simple as that.

Persistence is handled with a named volume for MongoDB data. Images are tagged properly: `rmwangi3/yolo-backend:1.0.0`.

## Ansible Playbook

The playbook runs through these roles in order:

1. **docker** - Installs Docker, Docker Compose, and the Python Docker library. Uses standard Ansible modules like `apt_key`, `apt_repository`, and `service`.

2. **clone_repo** - Clones the repo from GitHub into `/opt/yolo`. Also copies over the `.env` file with the MongoDB connection string.

3. **mongodb** - Sets up the database container. Creates the network and volume first, then pulls the image and runs the container.

4. **backend** - Builds the backend image from the Dockerfile, then deploys it. Waits for port 5000 to be available and tests the API endpoint.

5. **client** - Same thing for the frontend - build, deploy, wait, test. This one's on port 3000.

I'm using variables in `vars/main.yml` for configuration stuff - repo URL, container names, ports, etc. Makes it easy to change things without editing multiple files.

Tags let you run specific parts: `ansible-playbook playbook.yml --tags docker` just installs Docker, or `--skip-tags setup` skips the initial setup tasks.

The whole thing is idempotent so you can run it multiple times safely.

## Terraform (Stage 2)

Added Terraform integration in the `Stage_two` directory. It uses a `null_resource` to run Vagrant commands via `local-exec`. Not the most elegant solution but it works for this use case.

The playbook in Stage_two runs terraform init and apply, then calls the regular Ansible roles.

Run it with:
```bash
cd Stage_two
ansible-playbook playbook.yml -i ../inventory
```

## Vagrant

Using the `geerlingguy/ubuntu2004` box because it's well-maintained. Port forwarding maps 3000→3001 and 5000→5001 on the host. The VM gets a private IP at 192.168.56.10.

Vagrant runs the Ansible playbook automatically on `vagrant up`.

## Testing

The playbook includes some basic tests - checks if containers are running, hits the API endpoints, etc. 

For manual testing:
1. Go to http://192.168.56.10:3000
2. Add a product (name, price, description)
3. Run `vagrant reload` to restart everything
4. Check if the product is still there

That's about it.
