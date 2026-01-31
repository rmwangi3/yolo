# Yolo E-Commerce - Kubernetes Deployment

## Live URL
**http://34.121.63.230**

Deployed on GKE with React frontend, Node.js backend, and MongoDB.

## Architecture

**Kubernetes Objects:**
- StatefulSet (MongoDB) - persistent storage with 5Gi PVC
- Deployments (frontend/backend) - 2 replicas each
- LoadBalancer Service - exposes frontend
- ClusterIP Service - internal backend access

**Images:**
- `rmwangi3/yolo-backend:1.0.0`
- `rmwangi3/yolo-client:1.0.0`

## Deploy to GKE

```bash
# Create cluster
gcloud container clusters create yolo-cluster \
  --zone us-central1-a \
  --num-nodes 2 \
  --machine-type e2-small \
  --disk-size 20

# Deploy
gcloud container clusters get-credentials yolo-cluster --zone us-central1-a
cd Stage_two && ./deploy.sh

# Check status
kubectl -n yolo get all
```

## API Endpoints
- `GET /api/products` - List products
- `POST /api/products` - Add product
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product
