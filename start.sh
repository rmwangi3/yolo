#!/bin/bash
# Permanent solution for Docker container startup issues

echo "Stopping all containers..."
docker compose down -v 2>/dev/null

echo "Cleaning up any orphaned docker-proxy processes..."
sudo pkill -9 docker-proxy 2>/dev/null

echo "Removing stale containers and volumes..."
docker system prune -f 2>/dev/null

echo "Starting containers fresh..."
docker compose up -d

echo "Waiting for containers to stabilize..."
sleep 5

echo "Container status:"
docker ps

echo ""
echo "Application URLs:"
echo "Frontend: http://localhost:3000"
echo "Backend: http://localhost:5000"
