# Yolo E-commerce Deployment

e-commerce app deployed with Ansible and Terraform.

## Quick Start

```bash: run command
vagrant up
```

Access at http://192.168.56.10:3000

## Stage 2 (Terraform Integration)

```bash: run command
cd Stage_two
ansible-playbook playbook.yml -i ../inventory
```

## If VirtualBox Doesn't Work

Sometimes VirtualBox has issues. Use Docker Compose instead:

```bash: run command
docker compose up -d
```

Then go to http://localhost:3000

## What's Inside

- `Vagrantfile` - VM setup
- `playbook.yml` - Main Ansible playbook  
- `roles/` - Ansible roles (docker, mongodb, backend, client)
- `vars/main.yml` - Configuration variables
- `docker-compose.yml` - Docker setup
- `explanation.md` - Implementation details

## Testing

Add a product through the UI, then restart with `vagrant reload` to check if it persists.

Or use the API:
```bash command
curl http://localhost:5000/api/products
```

## Troubleshooting

**VM won't start?**
```bash command
vagrant destroy -f
vagrant up
```

**Can't connect?**
```bash command
vagrant ssh
docker ps
```

**Backend issues?**
```bash command
vagrant ssh
docker logs yolo-backend
```

## DockerHub Images

Backend: `rmwangi3/yolo-backend:1.0.0`  
Client: `rmwangi3/yolo-client:1.0.0`

Push them with:
```bash: run command
docker login
docker push rmwangi3/yolo-backend:1.0.0
docker push rmwangi3/yolo-client:1.0.0
```
