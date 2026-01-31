# Yolo E-Commerce Deployment Explanation

Built this e-commerce app through different stages - started with local VMs and ended up deploying to Google Cloud.

---

## Week 5: Kubernetes on GKE

### What I Built

Deployed the full-stack app on GKE with Kubernetes.

**Tech Stack:**
- Frontend: React with nginx
- Backend: Node.js/Express
- Database: MongoDB

**Live URL:** http://34.121.63.230

### Kubernetes Objects I Used

**1. Namespace**
Made a `yolo` namespace to keep everything organized and seperate from other stuff.

**2. StatefulSet (MongoDB)**
Had to use StatefulSet for Mongo instead of regular Deployment because:
- MongoDB needs a stable network identity (always mongo-0)
- Data needs to persist even when pods restart
- Pods get created/deleted in order

Used volumeClaimTemplates so it automatically creates PVCs. Set it to 5Gi with ReadWriteOnce access.

**3. Deployments (Frontend & Backend)**
- Backend: 2 replicas incase one fails
- Frontend: 2 replicas with LoadBalancer
- Added health probes and resource limits so they dont use too much

**4. Services**

- **LoadBalancer (Frontend):** Makes the frontend accessible from internet, GKE gives you an external IP automatically
- **ClusterIP (Backend):** Internal only, frontend talks to backend inside the cluster which is more secure
- **Headless (MongoDB):** clusterIP set to None, gives direct access to StatefulSet pods

**5. Persistent Storage**
- PVC: 5Gi with standard-rwo storage class
- Data survives pod restarts and deletions
- GKE handles the PersistentVolume provisioning automatically

### Why I Chose This Setup

**Scalability:** Can scale frontend and backend seperately with kubectl scale

**High Availability:** Multiple replicas means if one pod dies the app keeps running

**Data Persistence:** StatefulSet + PVC ensures database data doesn't get lost

**Security:** Backend isn't exposed to the internet, only frontend is public

**Cloud Native:** Using GKE managed services makes it easier (LoadBalancer, storage, etc)

### How I Deployed It

1. Created GKE cluster (2 nodes, e2-small machines)
2. Applied namespace first
3. Deployed MongoDB StatefulSet + headless service
4. Deployed backend + ClusterIP service
5. Deployed frontend + LoadBalancer service
6. Verified everything with `kubectl get all`

### Problems I Hit & Fixed

**Backend readiness probe kept failing:**
Root path was returning 404. Changed from HTTP probe to TCP socket check on port 5000 and it worked.

**GKE said disk size too small:**
Had to increase from 10GB to 20GB cause GKE images need atleast 12GB.

**Image pull was taking forever:**
Pre-pushed images to Docker Hub and used specific tags (v1.0.0) instead of latest.

### Git Workflow

- Made a `k8s-deploy` branch for the Kubernetes work
- Tested everything on Minikube locally first
- Merged to main after GKE deployment worked
- Tagged Docker images with v1.0.0 for version control

### Why I Used Specific Image Tags

Using `rmwangi3/yolo-backend:1.0.0` instead of `:latest` because:
- Deployments are reproducible (same image every time)
- Can rollback easily if something breaks
- Know exactly which version is running
- No suprises from "latest" suddenly changing

### Cost Breakdown
- 2x e2-small nodes: ~$25/month
- Persistent disk: ~$0.80/month  
- LoadBalancer: ~$18/month
- **Total:** ~$44/month

Good thing Google gives $300 free credits so this doesn't cost me anything yet.

### Monitoring Commands I Use
```bash
# Check if pods are running
kubectl -n yolo get pods

# Get the LoadBalancer external IP
kubectl -n yolo get svc

# View backend logs
kubectl -n yolo logs -f deployment/backend

# Check MongoDB logs
kubectl -n yolo logs mongo-0

# Verify storage
kubectl -n yolo get pvc
```

---

## Earlier Stages: Ansible + Terraform

Before Kubernetes, I used Ansible and Terraform for local development with VirtualBox/Vagrant.

### How the Ansible Playbook Works

Runs in this order:
```
pre_tasks → docker → clone_repo → mongodb → backend → client → post_tasks
```

Each step depends on the previous one. If you change the order stuff breaks.

### What Each Role Does

**Pre-tasks:** Update apt, install git, curl, python3-pip (can't do anything without these)

**Docker:** Install Docker Engine and Compose, start daemon. This has to go first obviously.

**Clone Repo:** Get code from GitHub, create .env file, setup folders

**MongoDB:** Create Docker network and volume, start MongoDB container, wait for it to be ready

**Backend:** Build backend image, start container on port 5000, connect to network

**Client:** Build React frontend, start with nginx on port 3000

**Post-tasks:** Just shows the URLs where you can access the app

### Variables & Tags

Put all config in `vars/main.yml` so I only change port numbers in one place.

Can run specific parts with tags:
- `--tags setup` - just install Docker and clone repo
- `--tags containers` - only containers (skip setup)
- `--skip-tags mongodb` - skip database

### Terraform Part (Stage 2)

Terraform automates VM creation with `local-exec` to run `vagrant up`.

Run it: `cd Stage_two && ansible-playbook playbook.yml -i ../inventory`

### Why Order Matters

- No Docker → nothing can run
- No repo → can't build images  
- No MongoDB → backend crashes on startup
- No backend → frontend has nothing to connect to

Thats why the order is important.
