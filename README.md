# Yolo E-Commerce - Kubernetes Deployment

This is a full-stack e-commerce application I deployed on Google Kubernetes Engine (GKE). The application uses React for the frontend, Node.js/Express for the backend, and MongoDB as the database.

**Live URL:** http://34.121.63.230

## Overview

This project involves deploying a containerized microservices application on GKE. The main components include:
- React frontend served through nginx
- Node.js/Express API for the backend
- MongoDB with persistent storage
- Load balancing and auto-healing capabilities

## Architecture

### Kubernetes Resources

**Namespace:** I created a `yolo` namespace to keep all the application resources organized and separated from other workloads.

**StatefulSet for MongoDB** with 5Gi persistent volume
- I used a StatefulSet instead of a regular Deployment because MongoDB needs stable storage and a consistent network identity
- When pods restart, they reconnect to the same data
- Each pod gets its own PersistentVolumeClaim automatically through volumeClaimTemplates

**Deployments:** Backend runs with 3 replicas and Frontend with 2 replicas
- These are stateless services that can scale horizontally
- Health checks ensure only healthy pods receive traffic
- Rolling updates allow for zero downtime during deployments

**Services:**
- Frontend: LoadBalancer service on port 80 to expose the app to the internet
- Backend: ClusterIP service on port 5000 for internal communication only
- MongoDB: Headless service on port 27017 to provide stable DNS for StatefulSet pods

### Container Images

I'm using semantic versioning instead of the latest tag:
- `rmwangi3/yolo-backend:1.0.0`
- `rmwangi3/yolo-client:1.0.0`

Using specific version tags helps track exactly what's deployed and makes rollbacks easier if something breaks.

## Prerequisites

To deploy this application, you'll need:
- GCP account with billing enabled
- gcloud CLI installed
- kubectl v1.20 or higher
- GCP quotas: at least 2 CPUs and 1 external IP

## Deployment Steps

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

### 2. Deploy the Application

Quick deployment using the script:
```bash
cd Stage_two
chmod +x deploy.sh
./deploy.sh
```

Or deploy manually:
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -n yolo -f k8s/mongo-headless-service.yaml
kubectl apply -n yolo -f k8s/mongo-statefulset.yaml
kubectl apply -n yolo -f k8s/backend-deployment.yaml
kubectl apply -n yolo -f k8s/backend-service.yaml
kubectl apply -n yolo -f k8s/frontend-deployment.yaml
kubectl apply -n yolo -f k8s/frontend-service.yaml
```

### 3. Get External IP Address

```bash
kubectl -n yolo get svc frontend
# Wait a few minutes for the EXTERNAL-IP to be assigned
```

### 4. Test the Deployment

```bash
curl http://<EXTERNAL-IP>/api/products
# Should return: []
```

## API Endpoints

The application exposes the following endpoints at: `http://34.121.63.230`

- **GET** `/api/products` - List all products
- **POST** `/api/products` - Create a new product
- **GET** `/api/products/:id` - Get a single product
- **PUT** `/api/products/:id` - Update a product
- **DELETE** `/api/products/:id` - Delete a product

Example usage:
```bash
curl -X POST http://34.121.63.230/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999,"description":"Gaming laptop"}'
```

## Troubleshooting

If pods aren't starting:
```bash
kubectl -n yolo get pods
kubectl -n yolo describe pod <pod-name>
kubectl -n yolo logs <pod-name>
```

If you can't access the application:
```bash
kubectl -n yolo get svc frontend
# Make sure the EXTERNAL-IP is assigned and not showing <pending>
```

For database connection issues:
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

## Technology Stack

- **Frontend:** React with nginx as the web server
- **Backend:** Node.js with Express framework and Mongoose for MongoDB interaction
- **Database:** MongoDB
- **Containerization:** Docker
- **Orchestration:** Kubernetes on Google Kubernetes Engine
- **Version Control:** Git with Docker Hub for image registry

## Scaling

You can scale the deployments up or down as needed:
```bash
kubectl -n yolo scale deployment backend --replicas=5
kubectl -n yolo scale deployment frontend --replicas=3
```

## Monitoring

To check resource usage and events:
```bash
kubectl -n yolo top pods
kubectl -n yolo get events --sort-by='.lastTimestamp'
```

## Cost Estimate

Running this setup on GKE with 2 e2-small nodes costs approximately:
- Compute resources: ~$25/month
- Persistent storage: ~$1/month (5Gi)
- Load Balancer: ~$18/month
- **Total: ~$44/month**

This is covered by the $300 GCP free credits available for students.

## Cleanup

To delete the entire cluster and all resources:
```bash
gcloud container clusters delete yolo-cluster --zone us-central1-a
```

## Additional Documentation

- [explanation.md](explanation.md) - Detailed explanation of implementation choices
- [Stage_two/README.md](Stage_two/README.md) - Information about Terraform and Ansible setup
