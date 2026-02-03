# Yolo E-Commerce - Implementation Choices

**Live:** http://34.121.63.230

Explaining the key decisions I made for this Kubernetes deployment.

## 1. Kubernetes Objects

### Why StatefulSet for MongoDB?

Used a **StatefulSet** instead of a Deployment for MongoDB:

- **Stable Storage** - each pod gets its own persistent volume that survives restarts
- **Stable Network Identity** - pods get predictable names (mongo-0, mongo-1, etc.)
- **Ordered Operations** - pods start and stop in order
- **Direct Pod Access** - headless service allows direct pod connections via DNS

With a regular Deployment you'd lose data every time a pod restarts. StatefulSet fixes this by automatically creating a PersistentVolumeClaim for each pod using volumeClaimTemplates.

Config:
```yaml
volumeClaimTemplates:
- metadata:
    name: mongo-data
  spec:
    accessModes: [ "ReadWriteOnce" ]
    storageClassName: "standard-rwo"
    resources:
      requests:
        storage: 5Gi
```

### Why Deployments for Backend & Frontend?

Used **Deployments** because they're stateless:
- Easy horizontal scaling
- Smooth rolling updates
- Auto-replacement of failed pods
- All pods are interchangeable

Both have 2 replicas for high availability.

## 2. Exposing to Internet

### LoadBalancer Service

Chose **LoadBalancer** to expose the frontend:

What it does:
- GKE provisions an external IP (34.121.63.230)
- Distributes traffic across healthy frontend pods
- Only routes to pods passing health checks

**Why not NodePort?**
Exposes high ports (30000-32767) requiring URLs like `http://34.121.63.230:30123`.

**Why not Ingress?**
Overkill for a single app. Better for multiple apps/domains with SSL and routing needs.

Result: Clean URL (http://34.121.63.230) with automatic load balancing.

### Internal Services

- Backend: ClusterIP (internal only) - not exposed for security
- MongoDB: Headless service (clusterIP: None) - DNS for StatefulSet pods

## 3. Persistent Storage

### How It Works

StatefulSet's volumeClaimTemplates creates persistent storage automatically:

1. mongo-0 pod starts → Kubernetes creates PersistentVolumeClaim "mongo-data-mongo-0"
2. GKE provisions 5Gi Google Persistent Disk
3. Disk mounts to `/data/db` in container
4. Pod restarts → reconnects to same disk

What survives:
- Database collections and documents
- Indexes and configurations
- User data

What causes data loss:
- Manually deleting the PVC
- Deleting persistent disk from GCP console
- Disk corruption (rare)

Verify:
```bash
kubectl -n yolo get pvc
# Shows: mongo-data-mongo-0  Bound  5Gi
```

## 4. Git Workflow

Feature branch workflow:

1. Created branch: `git checkout -b k8s-deploy`
2. Developed locally: tested on Minikube first
3. Deployed to GKE: created cluster and applied manifests
4. Documented: updated README with live URL
5. Merged: `git merge k8s-deploy`
6. Tagged: `git tag v1.0.0`

Key commits:
- Initial K8s manifests
- StatefulSet implementation
- Service configurations
- Health probe fixes
- Documentation updates

## 5. Docker Image Tagging

### Using v1.0.0 Instead of :latest

Used specific version tags (`rmwangi3/yolo-backend:1.0.0`) instead of `:latest`.

Problems with :latest:
- Tag can point to different images over time
- Pod restarts might pull different versions
- Can't determine running version
- Difficult rollbacks
- Dev and prod might differ

Benefits of version tags:
- Reproducible - same tag = same image
- Easy rollbacks
- Clear audit trail
- Intentional updates only

Semantic versioning: v1.0.0 = MAJOR.MINOR.PATCH
- MAJOR for breaking changes
- MINOR for new features
- PATCH for bug fixes

## 6. Debugging & Challenges

### Challenge 1: Readiness Probe Failing

Problem: Backend pods failing readiness checks with 404 errors.

Cause: Readiness probe checked `GET /` but backend only has `/api/products`.

Fix: Changed to TCP socket check:
```yaml
readinessProbe:
  tcpSocket:
    port: 5000
  initialDelaySeconds: 10
```

Now just checks if port 5000 is open.

### Challenge 2: Disk Size Too Small

Problem: Cluster creation failed - "Boot disk size too small".

Cause: GKE requires minimum 12GB, used 10GB initially.

Fix: Increased to 20GB:
```bash
gcloud container clusters create yolo-cluster --disk-size 20
```

### Challenge 3: Slow Image Pulls

Problem: First deployment took 5-10 minutes for image downloads.

Fix:
- Pre-pushed images to Docker Hub
- Used specific version tags
- Set `imagePullPolicy: IfNotPresent`

Now deploys in 30-60 seconds.

## Architecture

```
Internet → LoadBalancer (34.121.63.230)
           ↓
       Frontend Pods (2 replicas)
           ↓ (ClusterIP)
       Backend Pods (2 replicas)
           ↓ (Headless)
       MongoDB (mongo-0)
           ↓
       PersistentVolume (5Gi)
```

Resources:
- Frontend: 2 replicas, 50m CPU / 64Mi RAM
- Backend: 2 replicas, 100m CPU / 128Mi RAM
- MongoDB: 1 replica, no limits (allows bursts)

Health Checks:
- All deployments have liveness & readiness probes
- Unhealthy pods removed from load balancing
- K8s restarts failed pods automatically

## Deployment Steps

1. Created GKE cluster (2 nodes, e2-small)
2. Applied namespace
3. Deployed MongoDB (StatefulSet + headless service)
4. Waited for mongo-0 ready
5. Deployed backend (deployment + service)
6. Deployed frontend (deployment + LoadBalancer)
7. Verified pods running and external IP assigned

Used deploy.sh script for repeatable deployments.

## Lessons Learned

- Always use specific image tags - makes debugging and rollbacks easier
- Test health probes carefully - wrong configs prevent deployments
- Check cloud provider minimums - GKE has specific requirements
- StatefulSets are powerful - perfect for databases needing persistence
- LoadBalancer is simple - best choice for single-app external access
