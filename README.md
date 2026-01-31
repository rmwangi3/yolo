# Yolo E-commerce App

Built this e-commerce app for my DevOps class. Started with Docker/Ansible, then added Terraform automation, and finally got it running on Kubernetes.

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

## Docker Images

My images are on Docker Hub:
- Backend: `rmwangi3/yolo-backend:1.0.0`
- Client: `rmwangi3/yolo-client:1.0.0`

## Kubernetes Deployment

Got the app running on Kubernetes now. All the manifests are in `Stage_two/k8s/`. Currently testing on Minikube but should work on GKE, its pretty straightforward.

To deploy on GKE:
```bash
gcloud container clusters get-credentials <CLUSTER_NAME> --zone <ZONE> --project <PROJECT_ID>
cd Stage_two
./deploy.sh
kubectl -n yolo get svc frontend  # grab the external IP
```

Using my Docker Hub images but you can swap them out in  deployment yamls if needed.

## Access the App

Running at: **http://192.168.49.2:32349**

(That's the Minikube IP - yours might be different)

Get your URL:
```bash
minikube service frontend -n yolo --url
```

Prefer localhost? Port-forward it:
```bash
kubectl -n yolo port-forward svc/frontend 3000:80
# then go to localhost:3000
```
