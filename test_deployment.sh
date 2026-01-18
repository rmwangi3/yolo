#!/bin/bash
# YOLO Deployment Test Script

set -e

echo "=== Testing YOLO Deployment ==="

# Test Vagrant
echo "1. Checking Vagrant VM..."
vagrant status | grep -q "running" && echo "✓ VM running" || echo "✗ VM not running"

# Test SSH
echo "2. Checking SSH connection..."
vagrant ssh -c "echo '✓ SSH OK'" || echo "✗ SSH failed"

# Test Docker
echo "3. Checking Docker containers..."
vagrant ssh -c "docker ps | grep -E 'mongo|backend|client'" && echo "✓ Containers running" || echo "✗ Containers not running"

# Test Ports
echo "4. Checking application ports..."
curl -s http://localhost:3000 > /dev/null && echo "✓ Frontend (3000)" || echo "✗ Frontend down"
curl -s http://localhost:5000 > /dev/null && echo "✓ Backend (5000)" || echo "✗ Backend down"

echo ""
echo "=== Test Complete ==="
