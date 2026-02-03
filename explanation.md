# Yolo E-Commerce - Implementation Choices

**Live App:** http://34.121.63.230

Key decisions for the Kubernetes deployment.

## 1. Kubernetes Objects Used

### Why StatefulSet for MongoDB?

I used a **StatefulSet** for MongoDB instead of a Deployment because:

- **Stable Storage:** Each pod gets its own persistent volume that survives restarts
- **Stable Network Identity:** Pods get predictable names (mongo-0, mongo-1, etc.)
- **Ordered Operations:** Pods start and stop in order
- **Direct Pod Access:** Headless service allows direct pod connections via DNS

With a regular Deployment, you'd lose data every time a pod restarts. StatefulSet solves this by automatically creating a PersistentVolumeClaim for each pod using `volumeClaimTemplates`.

Config snippet:
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

### Why Deployments for Backend and Frontend?

Used **Deployments** for backend and frontend because they're stateless:

- Easy horizontal scaling
- Smooth rolling updates
- Auto-replacement of failed pods
- All pods are interchangeable

Both have 2 replicas for high availability.

## 2. Exposing Pods to Internet Traffic

### LoadBalancer Service

I chose a **LoadBalancer** service to expose the frontend to the internet. Here's why:

**What it does:**
- GKE automatically provisions an external IP address (34.121.63.230)
- Distributes traffic across all healthy frontend pods
- Only sends traffic to pods that pass health checks

**Why not NodePort?**
Exposes high ports (30000-32767) requiring URLs like `http://34.121.63.230:30123`.

**Why not Ingress?**
Overkill for a single app. Better for multiple apps/domains with SSL and routing needs.

**Result:**
Clean URL (http://34.121.63.230) with automatic load balancing.

### Internal Services

- **Backend:** ClusterIP (internal only) - not exposed for security
- **MongoDB:** Headless service (clusterIP: None) - DNS for StatefulSet pods

## 3. Persistent Storage

### How It Works

The StatefulSet's `volumeClaimTemplates` automatically creates persistent storage:

1. When mongo-0 pod starts, Kubernetes creates a PersistentVolumeClaim called "mongo-data-mongo-0"
2. GKE provisions a 5Gi Google Persistent Disk
3. The disk mounts to `/data/db` inside the container
4. If the pod restarts, it reconnects to the same disk

**What survives:**
- All database collections and documents
- Indexes and configurations
- User data

**What can cause data loss:**
- Manually deleting the PVC
- Deleting the persistent disk from GCP console
- Disk corruption (rare)

You can verify persistence by checking:
```bash
kubectl -n yolo get pvc
# Shows: mongo-data-mongo-0  Bound  5Gi
```

## 4. Git Workflow

I followed a feature branch workflow:

1. **Created feature branch:** `git checkout -b k8s-deploy`
2. **Developed locally:** Tested manifests on Minikube first
3. **Deployed to GKE:** Created cluster and applied manifests
4. **Documented:** Updated README with live URL and instructions
5. **Merged to main:** `git merge k8s-deploy`
6. **Tagged release:** `git tag v1.0.0`

Key commits:
- Initial Kubernetes manifests
- StatefulSet implementation
- Service configurations
- Health probe fixes
- Documentation updates

## 5. Docker Image Tagging

### Using v1.0.0 Instead of :latest

I used specific version tags (`rmwangi3/yolo-backend:1.0.0`) instead of `:latest`. Here's why:

**Problems with :latest:**
- Tag can point to different images over time
- Pod restarts might pull different versions
- Can't determine running version
- Difficult rollbacks
- Dev and prod might differ

**Benefits of version tags:**
- Reproducible - same tag = same image
- Easy rollbacks
- Clear audit trail
- Intentional updates only

Following semantic versioning:
- **v1.0.0:** MAJOR.MINOR.PATCH
- Change MAJOR for breaking changes
- Change MINOR for new features
- Change PATCH for bug fixes

## 6. Debugging and Challenges

### Challenge 1: Readiness Probe Failing

**Problem:** Backend pods failing readiness checks with 404 errors.

**Cause:** Readiness probe checked `GET /` but backend only has `/api/products`.

**Fix:** Changed to TCP socket check:
```yaml
readinessProbe:
  tcpSocket:
    port: 5000
  initialDelaySeconds: 10
```

Now it just checks if port 5000 is open, which works perfectly.

### Challenge 2: GKE Disk Size Too Small

**Problem:** Cluster creation failed - "Boot disk size too small".

**Cause:** GKE requires minimum 12GB, used 10GB initially.

**Fix:** Increased to 20GB:
```bash
gcloud container clusters create yolo-cluster --disk-size 20
```

### Challenge 3: Slow Image Pulls

**Problem:** First deployment took 5-10 minutes for image downloads.

**Fix:** 
- Pre-pushed images to Docker Hub
- Used specific version tags
- Set `imagePullPolicy: IfNotPresent`

Now subsequent deployments take 30-60 seconds.

## Architecture Summary

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

**Resources:**
- Frontend: 2 replicas, 50m CPU / 64Mi RAM requests
- Backend: 2 replicas, 100m CPU / 128Mi RAM requests
- MongoDB: 1 replica (StatefulSet), no limits to allow bursts

**Health Checks:**
- All deployments have liveness and readiness probes
- Unhealthy pods automatically removed from load balancing
- Kubernetes restarts failed pods automatically

## Deployment Steps

1. Created GKE cluster (2 nodes, e2-small)
2. Applied namespace
3. Deployed MongoDB (StatefulSet + headless service)
4. Waited for mongo-0 pod to be ready
5. Deployed backend (deployment + service)
6. Deployed frontend (deployment + LoadBalancer service)
7. Verified all pods running and external IP assigned

Used `deploy.sh` script for repeatable deployments.

## Lessons Learned

1. **Always use specific image tags** - Makes debugging and rollbacks much easier
2. **Test health probes carefully** - Wrong probe configs can prevent deployments
3. **Check cloud provider minimums** - GKE has specific disk size requirements
4. **StatefulSets are powerful** - Perfect for databases needing persistent storage
5. **LoadBalancer is simple** - Best choice for single-app external access
