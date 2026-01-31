cd ~/week4/projects/yolo

# Backup existing README if needed
cp README.md README.md.backup 2>/dev/null || true

# Create the new README
cat > README.md << 'EOF'
# Yolo E-Commerce Application - Kubernetes Deployment

## 🌐 Live Application

**URL:** http://34.121.63.230

The application is deployed on Google Kubernetes Engine (GKE) and is fully functional.

---

## 📋 Project Overview

This is a full-stack e-commerce application deployed on Kubernetes with:
- **Frontend:** React application
- **Backend:** Node.js/Express API
- **Database:** MongoDB with persistent storage

---

## 🚀 Quick Start

### Access the Live Application
Visit: **http://34.121.63.230**

### API Endpoints
- `GET /api/products` - Get all products
- `POST /api/products` - Create a product
- `PUT /api/products/:id` - Update a product
- `DELETE /api/products/:id` - Delete a product

---

## 🏗️ Architecture

### Kubernetes Objects Used

1. **StatefulSet (MongoDB)**
   - Provides stable network identity
   - Persistent storage with 5Gi PVC
   - Ensures data persistence across restarts

2. **Deployments (Frontend & Backend)**
   - Frontend: 2 replicas with LoadBalancer
   - Backend: 2 replicas with ClusterIP (internal)

3. **Services**
   - LoadBalancer: Exposes frontend to internet
   - ClusterIP: Internal backend service
   - Headless: MongoDB StatefulSet service

4. **PersistentVolumeClaim**
   - 5Gi storage for MongoDB
   - StorageClass: standard-rwo
   - Survives pod restarts/deletions

---

## 📦 Deployment

### Prerequisites
- Google Cloud account with $300 free credits
- `gcloud` CLI installed
- `kubectl` installed
- Docker images on Docker Hub:
  - `rmwangi3/yolo-backend:1.0.0`
  - `rmwangi3/yolo-frontend:1.0.0`

### Deploy to GKE

```bash
# 1. Create GKE cluster
gcloud container clusters create yolo-cluster \
  --zone us-central1-a \
  --num-nodes 2 \
  --machine-type e2-small \
  --disk-size 20

# 2. Get credentials
gcloud container clusters get-credentials yolo-cluster --zone us-central1-a

# 3. Deploy application
cd Stage_two
./deploy.sh

# 4. Verify deployment
kubectl -n yolo get all
