# Kubernetes Deployment Explanation

## Architecture Overview

Deployed a full-stack e-commerce app on GKE using Kubernetes orchestration.

**Stack:**
- Frontend: React (nginx)
- Backend: Node.js/Express
- Database: MongoDB

**Live URL:** http://34.121.63.230

## Kubernetes Objects Used

### 1. Namespace
Created `yolo` namespace to isolate resources and keep things organized.

### 2. StatefulSet (MongoDB)
Used StatefulSet instead of Deployment because MongoDB needs:
- Stable network identity (mongo-0)
- Persistent storage that survives pod restarts
- Ordered pod creation/deletion

**volumeClaimTemplates:** Automatically creates PVCs for each pod. Set to 5Gi with ReadWriteOnce access mode.

### 3. Deployments (Frontend & Backend)
- **Backend:** 2 replicas for high availability
- **Frontend:** 2 replicas with LoadBalancer

Both have:
- Health probes (liveness/readiness)
- Resource limits (CPU/memory)
- Rolling update strategy

### 4. Services

**LoadBalancer (Frontend):**
- Exposes frontend to internet
- GKE provisions external IP automatically
- Routes traffic to frontend pods

**ClusterIP (Backend):**
- Internal only, not exposed
- Frontend talks to backend inside cluster
- More secure

**Headless Service (MongoDB):**
- clusterIP: None
- Gives direct access to StatefulSet pods
- Required for stable network identity

### 5. Persistent Storage
- PVC requests 5Gi storage
- StorageClass: standard-rwo (ReadWriteOnce)
- Data survives pod restarts/deletions
- GKE provisions PersistentVolume automatically

## Why This Architecture?

**Scalability:** Can scale frontend/backend independently with `kubectl scale`

**High Availability:** Multiple replicas ensure uptime if a pod fails

**Data Persistence:** StatefulSet + PVC means data survives crashes

**Security:** Backend not exposed to internet, only accessible internally

**Cloud Native:** Uses GKE managed services (LoadBalancer, storage provisioning)

## Deployment Process

1. Created GKE cluster (2 nodes, e2-small)
2. Applied namespace first
3. Deployed MongoDB StatefulSet + headless service
4. Deployed backend + ClusterIP service
5. Deployed frontend + LoadBalancer service
6. Verified with `kubectl get all`

## Challenges & Solutions

**Issue 1:** Backend readiness probe failing (404 on root path)
- **Solution:** Changed from HTTP probe to TCP socket check on port 5000

**Issue 2:** GKE required minimum 12GB disk
- **Solution:** Increased disk size from 10GB to 20GB

**Issue 3:** Image pull taking too long
- **Solution:** Pre-pushed images to Docker Hub, used specific tags (v1.0.0)

## Git Workflow

- Created `k8s-deploy` branch for Kubernetes work
- Tested deployment on Minikube locally first
- Merged to main after GKE deployment successful
- Tagged Docker images with semantic versioning (1.0.0)

## Image Tags Best Practice

Using `rmwangi3/yolo-backend:1.0.0` instead of `:latest` because:
- Reproducible deployments
- Easy rollbacks
- Clear version tracking
- No surprises from "latest" changing

## Health Checks

**Liveness Probe:** Restarts unhealthy containers
**Readiness Probe:** Removes unready pods from service endpoints

Ensures only healthy pods receive traffic.

## Cost

- 2x e2-small nodes: ~$25/month
- Persistent disk: ~$0.80/month  
- LoadBalancer: ~$18/month
- **Total:** ~$44/month (covered by $300 GCP free credits)

## Monitoring Commands

```bash
# Check pods
kubectl -n yolo get pods

# Check services
kubectl -n yolo get svc

# View logs
kubectl -n yolo logs -f deployment/backend
kubectl -n yolo logs -f deployment/frontend
kubectl -n yolo logs mongo-0

# Check PVC
kubectl -n yolo get pvc
```

## Previous Stages (Archived)

Earlier stages used Vagrant, Ansible, Terraform, and Docker Compose for local development. See `explanation-ansible-backup.md` for details on the Ansible playbook structure and role dependencies.
