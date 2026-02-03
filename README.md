# Yolo E-Commerce - Kubernetes Deployment

A full-stack e-commerce app running on Google Kubernetes Engine. Built with React frontend, Node.js backend, and MongoDB database.

## Live Application

**URL:** http://34.121.63.230

## What's Inside

Containerized microservices on GKE:
- React frontend (nginx)
- Node.js/Express API backend
- MongoDB with persistent storage
- Load balancing and auto-healing

## Architecture

### Kubernetes Setup

**Namespace:** `yolo` (keeps everything organized)

**StatefulSet:** MongoDB with 5Gi persistent volume
- Used StatefulSet because MongoDB needs stable storage and network identity
- Data persists even when pods restart
- Each pod gets its own PersistentVolumeClaim automatically

**Deployments:** Backend and Frontend (2 replicas each)
- Stateless services that can scale horizontally
- Health checks ensure only healthy pods receive traffic
- Rolling updates for zero-downtime deployments

**Services:**
- Frontend: LoadBalancer (port 80) - exposes app to internet
- Backend: ClusterIP (port 5000) - internal only
- MongoDB: Headless service (port 27017) - stable DNS for StatefulSet pods

### Container Images

Using semantic versioning (not :latest tag):
- `rmwangi3/yolo-backend:1.0.0`
- `rmwangi3/yolo-client:1.0.0`

Why version tags? Reproducibility and easy rollbacks.

## Prerequisites

- GCP account with billing enabled
- `gcloud` CLI installed
- `kubectl` v1.20+
- GCP quotas: 2 CPUs, 1 external IP

## Quick Deployment

### 1. Create GKE Cluster

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

### 2. Deploy Application

```bash
cd Stage_two
chmod +x deploy.sh
./deploy.sh
```

Or manually:
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -n yolo -f k8s/mongo-headless-service.yaml
kubectl apply -n yolo -f k8s/mongo-statefulset.yaml
kubectl apply -n yolo -f k8s/backend-deployment.yaml
kubectl apply -n yolo -f k8s/backend-service.yaml
kubectl apply -n yolo -f k8s/frontend-deployment.yaml
kubectl apply -n yolo -f k8s/frontend-service.yaml
```

### 3. Get External IP

```bash
kubectl -n yolo get svc frontend
# Wait for EXTERNAL-IP to appear (may take 2-3 minutes)
```

### 4. Test

```bash
curl http://<EXTERNAL-IP>/api/products
# Should return: []
```

## API Endpoints

All endpoints use the base URL: `http://34.121.63.230`

- **GET** `/api/products` - List all products
- **POST** `/api/products` - Create new product
- **GET** `/api/products/:id` - Get single product
- **PUT** `/api/products/:id` - Update product
- **DELETE** `/api/products/:id` - Delete product

Example:
```bash
# Add a product
curl -X POST http://34.121.63.230/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999,"description":"Gaming laptop"}'
```

## Troubleshooting

**Pods not starting?**
```bash
kubectl -n yolo get pods
kubectl -n yolo describe pod <pod-name>
kubectl -n yolo logs <pod-name>
```

**Can't access external IP?**
```bash
kubectl -n yolo get svc frontend
# Check EXTERNAL-IP is assigned (not <pending>)
```

**Database issues?**
```bash
kubectl -n yolo exec -it mongo-0 -- mongo
# Check MongoDB is running
```

## Project Structure

```
yolo/
├── backend/              # Node.js API
│   ├── Dockerfile
│   ├── server.js
│   └── routes/
├── client/               # React frontend
│   ├── Dockerfile
│   ├── nginx.conf
│   └── src/
└── Stage_two/
    └── k8s/              # Kubernetes manifests
        ├── namespace.yaml
        ├── mongo-statefulset.yaml
        ├── mongo-headless-service.yaml
        ├── backend-deployment.yaml
        ├── backend-service.yaml
        ├── frontend-deployment.yaml
        └── frontend-service.yaml
```

## Technology Stack

- **Frontend:** React, nginx
- **Backend:** Node.js, Express, Mongoose
- **Database:** MongoDB
- **Container:** Docker
- **Orchestration:** Kubernetes on GKE
- **CI/CD:** Git, Docker Hub

## Scaling

Scale deployments up or down:
```bash
kubectl -n yolo scale deployment backend --replicas=3
kubectl -n yolo scale deployment frontend --replicas=3
```

## Monitoring

Check resource usage:
```bash
kubectl -n yolo top pods
kubectl -n yolo get events --sort-by='.lastTimestamp'
```

## Cost Estimate

Running on GKE (2 x e2-small nodes):
- Compute: ~$25/month
- Storage: ~$1/month (5Gi)
- Load Balancer: ~$18/month
- **Total:** ~$44/month

Covered by $300 GCP free credits.

## Cleanup

Delete everything:
```bash
gcloud container clusters delete yolo-cluster --zone us-central1-a
```

## Documentation

- [explanation.md](explanation.md) - Implementation choices
- [Stage_two/README.md](Stage_two/README.md) - Terraform/Ansible setup
