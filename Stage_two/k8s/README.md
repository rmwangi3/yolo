# Kubernetes Manifests

Manifests for deploying to GKE/Minikube.

**What's in here:**
- `namespace.yaml` - yolo namespace
- `mongo-statefulset.yaml` + `mongo-headless-service.yaml` - MongoDB with persistent storage
- `backend-deployment.yaml` + `backend-service.yaml` - backend API
- `frontend-deployment.yaml` + `frontend-service.yaml` - frontend (LoadBalancer)
- `ingress.yaml` - optional Ingress

**Deploy:**
```bash
kubectl apply -f namespace.yaml
kubectl apply -n yolo -f mongo-headless-service.yaml -f mongo-statefulset.yaml
kubectl apply -n yolo -f backend-deployment.yaml -f backend-service.yaml
kubectl apply -n yolo -f frontend-deployment.yaml -f frontend-service.yaml
```

Or just run `../deploy.sh` from the repo root, its easier.

**Check status:**
```bash
kubectl -n yolo get pods
kubectl -n yolo get svc frontend
```

Images are already set to `rmwangi3/yolo-backend:1.0.0` and `rmwangi3/yolo-client:1.0.0`. Change them if using your own.
