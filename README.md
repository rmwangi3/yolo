# Yolo E-Commerce - Kubernetes Deployment

Full-stack e-commerce app running on Google Kubernetes Engine. React frontend, Node.js backend, MongoDB database.

**Live URL:** http://34.121.63.230

## Overview

Deployed a containerized microservices app on GKE:
- React frontend (nginx)
- Node.js/Express API backend
- MongoDB with persistent storage
- Load balancing & auto-healing

## Architecture

### Kubernetes Setup

**Namespace:** `yolo` - keeps everything organized in its own space

**StatefulSet for MongoDB** (5Gi persistent volume)
- Used StatefulSet because MongoDB needs stable storage and network identity
- Data persists when pods restart
- Each pod gets its own PersistentVolumeClaim automatically

**Deployments:** Backend (3 replicas) and Frontend (2 replicas)
- Stateless services that scale horizontally
- Health checks make sure only healthy pods get traffic
- Rolling updates = zero downtime

**Services:**
- Frontend: LoadBalancer (port 80) - exposes the app to internet
- Backend: ClusterIP (port 5000) - internal only
- MongoDB: Headless service (port 27017) - stable DNS for StatefulSet pods

### Images

Using semantic versioning instead of :latest:
- `rmwangi3/yolo-backend:1.0.0`
- `rmwangi3/yolo-client:1.0.0`

Version tags mean you know exactly what's running and can rollback easily.

## Prerequisites

- GCP account with billing
- gcloud CLI
- kubectl v1.20+
- GCP quotas: 2 CPUs, 1 external IP

## Deployment

### Create GKE Cluster

```bash
gcloud container clusters create yolo-cluster \
  --zone us-central1-a \
  --num-nodes 2 \
  --machine-type e2-small \
  --disk-size 20 \
  --enable-autorepair \
  --enable-autoupgrade

gcloud container clusters get-credentials yolo-cluster --zone us-central1-a
```

### Deploy the App

Quick way:
```bash
cd Stage_two
chmod +x deploy.sh
./deploy.sh
```

Manual way:
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -n yolo -f k8s/mongo-headless-service.yaml
kubectl apply -n yolo -f k8s/mongo-statefulset.yaml
kubectl apply -n yolo -f k8s/backend-deployment.yaml
kubectl apply -n yolo -f k8s/backend-service.yaml
kubectl apply -n yolo -f k8s/frontend-deployment.yaml
kubectl apply -n yolo -f k8s/frontend-service.yaml
```

### Get the External IP

```bash
kubectl -n yolo get svc frontend
# Wait a few minutes for EXTERNAL-IP
```

### Test It

```bash
curl http://<EXTERNAL-IP>/api/products
# Returns: []
```

## API Endpoints

Base URL: `http://34.121.63.230`

- GET `/api/products` - list products
- POST `/api/products` - create product
- GET `/api/products/:id` - get single product
- PUT `/api/products/:id` - update product
- DELETE `/api/products/:id` - delete product

Example:
```bash
curl -X POST http://34.121.63.230/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999,"description":"Gaming laptop"}'
```

## Troubleshooting

Pods not starting?
```bash
kubectl -n yolo get pods
kubectl -n yolo describe pod <pod-name>
kubectl -n yolo logs <pod-name>
```

Can't access the app?
```bash
kubectl -n yolo get svc frontend
# Make sure EXTERNAL-IP is assigned (not <pending>)
```

Database problems?
```bash
kubectl -n yolo exec -it mongo-0 -- mongo
```

## Project Structure

```
yolo/
├── backend/
│   ├── Dockerfile
│   ├── server.js
│   └── routes/
├── client/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── src/
└── Stage_two/
    └── k8s/
        ├── namespace.yaml
        ├── mongo-statefulset.yaml
        ├── mongo-headless-service.yaml
        ├── backend-deployment.yaml
        ├── backend-service.yaml
        ├── frontend-deployment.yaml
        └── frontend-service.yaml
```

## Tech Stack

- Frontend: React, nginx
- Backend: Node.js, Express, Mongoose
- Database: MongoDB
- Container: Docker
- Orchestration: Kubernetes on GKE
- CI/CD: Git, Docker Hub

## Scaling

```bash
kubectl -n yolo scale deployment backend --replicas=3
kubectl -n yolo scale deployment frontend --replicas=3
```

## Monitoring

```bash
kubectl -n yolo top pods
kubectl -n yolo get events --sort-by='.lastTimestamp'
```

## Cost

Running on GKE with 2 e2-small nodes:
- Compute: ~$25/month
- Storage: ~$1/month (5Gi)
- Load Balancer: ~$18/month
- Total: ~$44/month

(Covered by $300 GCP free credits)

## Cleanup

```bash
gcloud container clusters delete yolo-cluster --zone us-central1-a
```

## More Info

- [explanation.md](explanation.md) - why I made specific choices
- [Stage_two/README.md](Stage_two/README.md) - Terraform/Ansible setup
