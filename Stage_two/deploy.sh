#!/bin/bash
# Stage 2 Deployment Script
# This script orchestrates Terraform and Ansible deployment

set -e

echo "=== Stage 2: Terraform + Ansible Deployment ==="
echo ""

# Step 1: Start Vagrant VM
echo "[1/3] Provisioning Vagrant VM..."
vagrant up

# Wait for VM to be ready
echo "Waiting for VM to be fully ready..."
sleep 20

# Step 2: Run Ansible playbook
echo "[2/3] Running Ansible playbook..."
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory playbook.yml

# Step 3: Verify deployment
echo "[3/3] Verifying deployment..."
vagrant ssh -c "docker ps"

echo ""
echo "=== Deployment Complete! ==="
echo "Frontend: http://localhost:3000"
echo "Backend: http://localhost:5000"
echo "MongoDB: localhost:2200 (auto-corrected from 27017)"
echo ""
echo "Access the VM: vagrant ssh"
