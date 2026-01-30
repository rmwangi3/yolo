#!/usr/bin/env bash
set -euo pipefail

# Simple deploy script for the yolo k8s manifests (GKE)
# Edit backend/frontend deployment files to set your Docker Hub image tags before running.

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
K8S_DIR="$ROOT_DIR/k8s"
NS_FILE="$K8S_DIR/namespace.yaml"

kubectl apply -f "$K8S_DIR/namespace.yaml"
kubectl apply -n yolo -f "$K8S_DIR/mongo-headless-service.yaml"
kubectl apply -n yolo -f "$K8S_DIR/mongo-statefulset.yaml"

kubectl apply -n yolo -f "$K8S_DIR/backend-deployment.yaml"
kubectl apply -n yolo -f "$K8S_DIR/backend-service.yaml"

kubectl apply -n yolo -f "$K8S_DIR/frontend-deployment.yaml"
kubectl apply -n yolo -f "$K8S_DIR/frontend-service.yaml"

# Optional ingress
# kubectl apply -n yolo -f "$K8S_DIR/ingress.yaml"

echo "Waiting for pods to be ready..."
kubectl -n yolo rollout status deploy/backend --timeout=120s || true
kubectl -n yolo rollout status deploy/frontend --timeout=120s || true

kubectl -n yolo get pods
kubectl -n yolo get svc

echo "If frontend is of type LoadBalancer, the EXTERNAL-IP may take a few minutes to appear."
