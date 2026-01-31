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
First thing I do is update apt and install git, curl, python3-pip. Can't do anything without these.
- **Modules**: `apt`

### 2. Docker Role
This goes first obviously. No Docker = no containers = nothing works.
- Install Docker Engine and Docker Compose
- Start Docker daemon
- Install Python Docker library (Ansible uses this to manage containers)
- **Modules**: `apt_key`, `apt_repository`, `apt`, `service`, `user`, `get_url`, `pip`, `docker_container`
- **Tags**: docker, setup

### 3. Clone Repo Role
Gotta get the code from GitHub first. I need the Dockerfiles and everything before I can build anything.
- Create /opt/yolo directory
- Clone the repo
- Make the .env file with MongoDB settings
- Set up folder for product images
- **Modules**: `file`, `git`, `copy`, `debug`
- **Tags**: clone, setup

### 4. MongoDB Role
Database has to be up before backend tries to connect or it breaks immediately.
- Create Docker network (yolo-network) so containers can talk to each other
- Create volume (mongo-data) to save database stuff even after container dies
- Pull MongoDB image
- Start MongoDB container
- Wait for it to actually be ready
- **Modules**: `docker_network`, `docker_volume`, `docker_image`, `docker_container`, `wait_for`, `docker_container_info`, `debug`
- **Tags**: mongodb, containers

### 5. Backend Role
Backend needs to run before the frontend so they can actually talk to each other.
- Build backend Docker image
- Kill old backend container if it's running
- Start new backend on port 5000
- Connect to yolo-network
- Set environment variables (MONGODB_URI, PORT)
- Mount the images volume
- Check that port 5000 is listening
- **Modules**: `docker_image`, `docker_container`, `wait_for`
- **Tags**: backend, containers

### 6. Client Role
Frontend is last because nothing else depends on it. Can put it anywhere really.
- Build React frontend with multi-stage Dockerfile (saves space)
- Stop old client container
- Start new client on port 3000 with nginx
- Connect to yolo-network
- Wait for nginx to be ready
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
2. Go to http://localhost:3000
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

## Week 5 — Kubernetes Deployment

Here's what I did for the Kubernetes setup.

**Objects I used:**
- Namespace (keeps everything organized)
- StatefulSet for MongoDB - needed this for persistent storage
- Regular Deployments for backend/frontend
- LoadBalancer Service for external access
- Threw in an Ingress example but haven't actually tested it

**Why StatefulSet:**
Needed StatefulSet for Mongo because it handles persistent storage properly. Each pod gets it's own volume and keeps the same identity if it restarts. Used volumeClaimTemplates so PVCs get created automatically.

**External Access:**
Went with LoadBalancer type Service. On GKE this gets you an external IP. For local testing with Minikube it's just a NodePort but works fine. Also included an Ingress manifest if you want to try that.

**Storage:**
Mongo StatefulSet creates PVCs from the volumeClaimTemplates. Set it to 5Gi per pod. On GKE these automatically provision PersistentVolumes.

**Git stuff:**
Worked on a k8s-deploy branch, then merged to main when everything was working. Tagged my images with v1.0.0 - way easier to track than using latest tags.

**Deploy & Debug:**
Just run `./deploy.sh` and it applies everything. When things break (they always do) I start with `kubectl get pods` then check logs. Added liveness/readiness probes so K8s actually knows when stuff is ready

# Kubernetes Deployment Explanation

## Architecture Overview

This application is deployed on Google Kubernetes Engine (GKE) using a microservices architecture with the following components:

### Components

1. **Frontend (React Application)**
   - Deployment with 2 replicas
   - Exposed via LoadBalancer service
   - Public IP: 34.121.63.230
   - Port: 80

2. **Backend (Node.js/Express API)**
   - Deployment with 2 replicas
   - Internal ClusterIP service
   - Port: 5000
   - Connected to MongoDB

3. **Database (MongoDB)**
   - StatefulSet with 1 replica
   - Persistent storage via PVC (5Gi)
   - Headless service for stable network identity

---

## Deployment Process

### 1. GKE Cluster Creation

```bash
gcloud container clusters create yolo-cluster \
  --zone us-central1-a \
  --num-nodes 2 \
  --machine-type e2-small \
  --disk-size 20
```

**Why these settings?**
- **2 nodes:** Provides redundancy and distributes workload
- **e2-small:** Cost-effective for development/testing
- **20GB disk:** Minimum required for GKE images

### 2. Kubernetes Resources

**Namespace:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: yolo
```

**MongoDB StatefulSet:**
- Uses StatefulSet for stable pod identity
- PersistentVolumeClaim for data persistence
- Headless service for direct pod access

**Backend Deployment:**
- 2 replicas for high availability
- TCP readiness probe (port 5000)
- Environment variables for configuration
- Resource limits: 500m CPU, 512Mi memory

**Frontend Deployment:**
- 2 replicas for redundancy
- LoadBalancer service type for external access
- Serves static React build

---

## Network Architecture

```
Internet
   ↓
LoadBalancer (34.121.63.230:80)
   ↓
Frontend Pods (2 replicas)
   ↓
Backend Service (ClusterIP)
   ↓
Backend Pods (2 replicas)
   ↓
MongoDB Headless Service
   ↓
MongoDB StatefulSet (mongo-0)
   ↓
PersistentVolume (5Gi)
```

---

## Key Kubernetes Concepts Used

### 1. Deployments
- **Frontend & Backend:** Stateless applications
- Rolling updates for zero-downtime deployments
- Replica management for scaling

### 2. StatefulSet
- **MongoDB:** Requires stable network identity and persistent storage
- Ordered pod creation and deletion
- Persistent volumes bound to specific pods

### 3. Services

**LoadBalancer (Frontend):**
```yaml
type: LoadBalancer
```
- Provisions external IP from cloud provider
- Routes external traffic to frontend pods

**ClusterIP (Backend):**
```yaml
type: ClusterIP
```
- Internal-only service
- Not exposed to internet
- Accessed by frontend within cluster

**Headless (MongoDB):**
```yaml
clusterIP: None
```
- Direct pod-to-pod communication
- DNS returns pod IPs directly
- Required for StatefulSet

### 4. PersistentVolumeClaim
```yaml
storageClassName: standard-rwo
accessModes:
  - ReadWriteOnce
```
- Dynamically provisioned storage
- Data persists across pod restarts
- Bound to specific node (ReadWriteOnce)

### 5. Probes

**Liveness Probe:**
- Checks if container is alive
- Restarts unhealthy containers

**Readiness Probe:**
- Checks if pod is ready to serve traffic
- Removes unready pods from service endpoints

---

## Deployment Commands

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Deploy MongoDB
kubectl apply -f mongo-statefulset.yaml

# Deploy Backend
kubectl apply -f backend-deployment.yaml

# Deploy Frontend
kubectl apply -f frontend-deployment.yaml

# Verify deployment
kubectl -n yolo get all
```

---

## Troubleshooting

### Issue: Backend Readiness Probe Failing

**Problem:** HTTP GET to `/` returned 404

**Solution:** Changed readiness probe from HTTP to TCP:
```yaml
readinessProbe:
  tcpSocket:
    port: 5000
  initialDelaySeconds: 10
  periodSeconds: 10
```

### Issue: Disk Size Too Small

**Problem:** GKE image requires minimum 12GB

**Solution:** Increased disk size from 10GB to 20GB

---

## Resource Management

### Backend Pod Resources
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

**Requests:** Guaranteed resources
**Limits:** Maximum resources allowed

---

## Scaling

### Manual Scaling
```bash
# Scale backend
kubectl -n yolo scale deployment backend --replicas=3

# Scale frontend
kubectl -n yolo scale deployment frontend --replicas=3
```

### Auto-scaling (Optional)
```bash
kubectl -n yolo autoscale deployment backend \
  --cpu-percent=50 \
  --min=2 \
  --max=10
```

---

## Monitoring

### Check Pod Status
```bash
kubectl -n yolo get pods
```

### View Logs
```bash
kubectl -n yolo logs -f deployment/backend
kubectl -n yolo logs -f deployment/frontend
kubectl -n yolo logs -f mongo-0
```

### Check Services
```bash
kubectl -n yolo get svc
```

---

## Cost Optimization

### Current Setup
- 2 x e2-small nodes: ~$25/month
- 20GB persistent disk: ~$0.80/month
- LoadBalancer: ~$18/month
- **Total:** ~$44/month

### Covered by $300 Free Credits ✅

---

## Security Considerations

1. **Backend not exposed:** Only ClusterIP, internal access only
2. **MongoDB not exposed:** Headless service, no external access
3. **Frontend only public service:** LoadBalancer with public IP
4. **Resource limits:** Prevents resource exhaustion
5. **Network policies:** Can be added for additional isolation

---

## High Availability

1. **Multiple replicas:** Frontend and backend have 2 replicas each
2. **Pod anti-affinity:** Kubernetes distributes pods across nodes
3. **Readiness probes:** Only healthy pods receive traffic
4. **Persistent storage:** Data survives pod restarts

---

## CI/CD Integration (Future)

```yaml
# Example GitHub Actions workflow
- name: Build and push Docker image
  run: |
    docker build -t rmwangi3/yolo-backend:${{ github.sha }} .
    docker push rmwangi3/yolo-backend:${{ github.sha }}

- name: Deploy to GKE
  run: |
    kubectl set image deployment/backend \
      backend=rmwangi3/yolo-backend:${{ github.sha }} \
      -n yolo
```

---

## Conclusion

This deployment demonstrates:
- �� Containerized microservices architecture
- ✅ Kubernetes orchestration on GKE
- ✅ Persistent storage for stateful applications
- ✅ Load balancing and high availability
- ✅ Resource management and optimization
- ✅ Production-ready cloud deployment

**Live URL:** http://34.121.63.230
