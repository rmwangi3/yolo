# Yolo E-Commerce - My Deployment Explanation

I built this e-commerce application through different stages, starting with local VMs and eventually deploying it to Google Cloud Platform.

---

## Week 5: Kubernetes on GKE

### What I Built

For this assignment, I deployed the full-stack application on Google Kubernetes Engine using Kubernetes orchestration.

**Tech Stack:**
- Frontend: React with nginx
- Backend: Node.js/Express
- Database: MongoDB

**Live URL:** http://34.121.63.230

### Kubernetes Objects I Used

**1. Namespace**
I created a `yolo` namespace to keep everything organized and seperate from other stuff in the cluster.

**2. StatefulSet (MongoDB)**
I had to use StatefulSet for MongoDB instead of a regular Deployment because:
- MongoDB needs a stable network identity (always mongo-0)
- Data needs to persist even when pods restart
- Pods get created and deleted in a specific order

I used volumeClaimTemplates so it automatically creates PVCs. I set it to 5Gi with ReadWriteOnce access mode.

**3. Deployments (Frontend & Backend)**
- Backend: 3 replicas for high availability and load distribution
- Frontend: 2 replicas with LoadBalancer service
- I added health probes and resource limits so they dont use too much resources

**4. Services**

I used three different types of services:

- **LoadBalancer (Frontend):** This makes the frontend accessible from the internet. GKE automatically provisions an external IP address for you.
- **ClusterIP (Backend):** This is internal only, so the frontend talks to the backend inside the cluster which is more secure.
- **Headless (MongoDB):** I set clusterIP to None, which gives direct access to StatefulSet pods through DNS.

**5. Persistent Storage**
- PVC: 5Gi with standard-rwo storage class
- Data survives pod restarts and deletions
- GKE handles the PersistentVolume provisioning automatically, which makes it easier

### Why I Chose This Setup

**Scalability:** I can scale the frontend and backend seperately using kubectl scale commands.

**High Availability:** Having multiple replicas means if one pod dies the application keeps running.

**Data Persistence:** Using StatefulSet with PVC ensures the database data doesn't get lost when pods restart.

**Security:** The backend isn't exposed to the internet directly, only the frontend is public-facing.

**Cloud Native:** Using GKE managed services makes everything easier to manage (LoadBalancer provisioning, storage, etc).

### How I Deployed It

The deployment process I followed:

1. Created a GKE cluster with 2 nodes using e2-small machine types
2. Applied the namespace first to create the isolated environment
3. Deployed MongoDB StatefulSet along with the headless service
4. Deployed the backend with its ClusterIP service
5. Deployed the frontend with the LoadBalancer service
6. Verified everything was running correctly using `kubectl -n yolo get all`

### Problems I Hit & How I Fixed Them

**Backend readiness probe kept failing:**
The root path was returning a 404 error. I changed it from an HTTP probe to a TCP socket check on port 5000 and that fixed it.

**GKE said disk size was too small:**
I had to increase the node disk size from 10GB to 20GB because GKE images need atleast 12GB of space.

**Image pull was taking forever:**
I pre-pushed the images to Docker Hub and started using specific version tags (v1.0.0) instead of the latest tag. This made deployments much faster and more predictable.

### Git Workflow

During development, I followed this workflow:
- Made a `k8s-deploy` branch for the Kubernetes work
- Tested everything on Minikube locally first before deploying to GKE
- Merged to main after confirming the GKE deployment worked correctly
- Tagged Docker images with v1.0.0 for proper version control
- Multiple commits throughout tracking the development process

### Why I Used Specific Image Tags

I'm using `rmwangi3/yolo-backend:1.0.0` instead of `:latest` because:
- Deployments become reproducible (you get the same image every time)
- Makes it easier to rollback if something breaks
- You know exactly which version is running in production
- No suprises from the "latest" tag suddenly changing

### Cost Breakdown

Running 2x e2-small nodes costs around $25 per month, the persistent disk is about $0.80 per month, and the LoadBalancer is roughly $18 per month. Total comes to around $44 per month, but since Google provides $300 in free credits for students, I'm not paying anything for now.

### Monitoring Commands I Use

```bash
# Check if pods are running
kubectl -n yolo get pods

# Get the LoadBalancer external IP
kubectl -n yolo get svc

# View backend logs in real-time
kubectl -n yolo logs -f deployment/backend

# Check MongoDB logs
kubectl -n yolo logs mongo-0

# Verify storage is working
kubectl -n yolo get pvc
```

---

## Earlier Stages: Ansible + Terraform

Before moving to Kubernetes, I used Ansible and Terraform for local development with VirtualBox and Vagrant.

### How the Ansible Playbook Works

The playbook runs in this specific order:

pre_tasks → docker → clone_repo → mongodb → backend → client → post_tasks

Each step depends on the previous one completing successfully. If you change the order, stuff breaks.

### What Each Role Does

**Pre-tasks:** Updates apt packages and installs git, curl, and python3-pip. You cant do anything without these basic tools installed first.

**Docker:** Installs Docker Engine and Docker Compose, then starts the daemon. This has to go first obviously since everything else runs in containers.

**Clone Repo:** Gets the code from GitHub, creates the .env file, and sets up the necessary folders.

**MongoDB:** Creates the Docker network and volume, starts the MongoDB container, and waits for it to be ready before continuing.

**Backend:** Builds the backend image from the Dockerfile and starts the container on port 5000, connecting it to the network.

**Client:** Builds the React frontend and starts it with nginx on port 3000.

**Post-tasks:** Just displays the URLs where you can access the running application.

### Variables & Tags

I put all the configuration in vars/main.yml so I only have to change port numbers and settings in one place.

You can run specific parts using tags:
- `--tags setup` - just installs Docker and clones the repo
- `--tags containers` - only handles containers (skips the setup steps)
- `--skip-tags mongodb` - skips the database deployment

### Terraform Part (Stage 2)

Terraform automates the VM creation process using local-exec provisioner to run vagrant up.

You run it like this: `cd Stage_two && ansible-playbook playbook.yml -i ../inventory`

### Why Order Matters

The order of execution is really important because:
- No Docker means nothing can run at all
- No repo means you cant build the images
- No MongoDB means the backend crashes immediately on startup
- No backend means the frontend has nothing to connect to

Thats why I kept the order strict in the playbook.
