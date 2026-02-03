# Yolo E-Commerce - Implementation Choices

**Live App:** http://34.121.63.230

This document explains the key decisions made during the Kubernetes deployment for the Week 5 assessment.

## 1. Kubernetes Objects Used

### Why StatefulSet for MongoDB?

I used a **StatefulSet** for MongoDB instead of a regular Deployment because databases need special treatment:

- **Stable Storage:** Each pod gets its own persistent volume that sticks with it even if the pod restarts
- **Stable Network Identity:** Pods get predictable names (mongo-0, mongo-1, etc.) instead of random names
- **Ordered Operations:** Pods start and stop in a specific order, which is important for databases
- **Direct Pod Access:** The headless service lets you connect directly to specific pods using DNS

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

Used regular **Deployments** for backend and frontend because they're stateless - they don't need to remember anything between restarts:

- Easy to scale horizontally (just add more replicas)
- Rolling updates work smoothly
- If a pod dies, Kubernetes replaces it instantly
- All pods are identical and interchangeable

Both have 2 replicas for high availability.

## 2. Exposing Pods to Internet Traffic

### LoadBalancer Service

I chose a **LoadBalancer** service to expose the frontend to the internet. Here's why:

**What it does:**
- GKE automatically provisions an external IP address (34.121.63.230)
- Distributes traffic across all healthy frontend pods
- Only sends traffic to pods that pass health checks

**Why not NodePort?**
NodePort exposes weird high-numbered ports (like 30000-32767). Users would have to type `http://34.121.63.230:30123` which looks unprofessional.

**Why not Ingress?**
Ingress is overkill for a single application. It's more useful when you have multiple apps/domains and need SSL certificates, routing rules, etc.

**The Result:**
Clean URL (http://34.121.63.230) that automatically load balances across frontend pods.

### Internal Services

- **Backend:** ClusterIP service (internal only) - not exposed to internet for security
- **MongoDB:** Headless service (clusterIP: None) - provides DNS for StatefulSet pods

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
- The tag can point to different images over time
- Pod restarts might pull a different version unexpectedly
- Can't tell what version is actually running
- Difficult to rollback to previous versions
- Dev and prod might run different code

**Benefits of version tags:**
- Reproducible deployments - same tag = same image always
- Easy rollbacks - just change to v1.0.0 → v0.9.0
- Clear audit trail of what's deployed
- Intentional updates only

Following semantic versioning:
- **v1.0.0:** MAJOR.MINOR.PATCH
- Change MAJOR for breaking changes
- Change MINOR for new features
- Change PATCH for bug fixes

## 6. Debugging and Challenges

### Challenge 1: Readiness Probe Failing

**Problem:** Backend pods kept failing readiness checks with 404 errors.

**Cause:** The readiness probe was checking `GET /` but the backend only has `/api/products` endpoint.

**Fix:** Changed from HTTP check to TCP socket check:
```yaml
readinessProbe:
  tcpSocket:
    port: 5000
  initialDelaySeconds: 10
```

Now it just checks if port 5000 is open, which works perfectly.

### Challenge 2: GKE Disk Size Too Small

**Problem:** Cluster creation failed with "Boot disk size too small" error.

**Cause:** GKE requires minimum 12GB boot disk, I used 10GB initially.

**Fix:** Increased to 20GB:
```bash
gcloud container clusters create yolo-cluster --disk-size 20
```

### Challenge 3: Slow Image Pulls

**Problem:** First deployment took 5-10 minutes waiting for images to download.

**Fix:** 
- Pre-pushed images to Docker Hub before deploying
- Used specific version tags (1.0.0)
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

---

**Version:** 1.0.0  
**Date:** February 2026  
**Project:** Week 5 Kubernetes Assessment
