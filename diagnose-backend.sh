#!/bin/bash

echo "=== BACKEND DIAGNOSTICS ==="
echo ""

echo "[1] Check all containers status:"
docker ps -a
echo ""

echo "[2] Check backend container logs:"
docker logs backend --tail 50
echo ""

echo "[3] Check MongoDB connection:"
docker exec mongodb mongosh --eval "db.adminCommand('ping')" 2>/dev/null || echo "MongoDB connection test failed"
echo ""

echo "[4] Check if backend process is running inside container:"
docker exec backend ps aux | grep node || echo "Node process not found"
echo ""

echo "[5] Check backend port 5000:"
ss -tuln | grep 5000 || echo "Port 5000 not listening"
