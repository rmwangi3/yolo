Stage Two — Kubernetes Manifests

This folder contains Kubernetes manifests for deploying the `yolo` app to a GKE cluster.

Files:
- `namespace.yaml` — creates `yolo` namespace
- `mongo-headless-service.yaml` — headless service for StatefulSet
- `mongo-statefulset.yaml` — MongoDB StatefulSet with `volumeClaimTemplates`
- `backend-deployment.yaml` + `backend-service.yaml` — backend Deployment and Service
- `frontend-deployment.yaml` + `frontend-service.yaml` — frontend Deployment and Service (LoadBalancer)
- `ingress.yaml` — optional Ingress (GCE) to route traffic to the frontend

Before applying:
1. Build and push your Docker images to Docker Hub with immutable tags, e.g. `dockerhub-username/backend:v1.0.0` and `dockerhub-username/client:v1.0.0`.
2. Edit `backend-deployment.yaml` and `frontend-deployment.yaml` and replace `YOUR_DOCKERHUB_USERNAME/<service>:latest` with your pushed image tags.

Deploy (example):

```bash
kubectl apply -f namespace.yaml
kubectl apply -n yolo -f mongo-headless-service.yaml
kubectl apply -n yolo -f mongo-statefulset.yaml
kubectl apply -n yolo -f backend-deployment.yaml -f backend-service.yaml
kubectl apply -n yolo -f frontend-deployment.yaml -f frontend-service.yaml
# Optional: kubectl apply -n yolo -f ingress.yaml

Optional: enable a 3-node MongoDB replica set (extra credit)

1. Apply the 3-node StatefulSet:

```bash
kubectl apply -n yolo -f mongo-statefulset-replicaset.yaml
```

2. Apply the init Job to form the replica set:

```bash
kubectl apply -n yolo -f mongo-init-job.yaml
kubectl -n yolo logs job/mongo-init-replicaset
```

Notes:
- The `mongo-statefulset-replicaset.yaml` will create three PVCs (one per pod). On GKE these will be dynamically provisioned.
- Keep the original single-node `mongo-statefulset.yaml` for simple local testing; deploy only one of the two StatefulSets at a time to avoid conflicts.
```

Check rollout status and get the external IP for the frontend service:

```bash
kubectl -n yolo get pods
kubectl -n yolo get svc frontend
```

Notes:
- The `StatefulSet` uses `volumeClaimTemplates` which on GKE will dynamically provision PersistentVolumes.
- For production, use stable image tags and consider setting resource requests/limits and readiness/liveness probes.
