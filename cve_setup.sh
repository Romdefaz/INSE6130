#!/bin/bash

# Simple CVE-2019-5736 Setup Script
# Quick automation without interactive prompts

set -e

echo "[*] Building execution container..."
sudo docker build -t cve:execution ./execution

echo "[*] Cleaning up existing control container..."
sudo docker stop control 2>/dev/null || true
sudo docker rm control 2>/dev/null || true

echo "[*] Starting control container..."
sudo docker run -d --rm --name control cve:execution

echo "[*] Waiting for container to start..."
sleep 2

echo "[*] Building malicious image..."
sudo docker build -t cve:malicious_image ./malicious_image

echo "[*] pulling falco image..."
sudo docker pull falcosecurity/falco:0.35.1
echo "[*] Setup complete!"
echo ""
echo "Container 'control' is running"
echo "Malicious image 'cve:malicious_image' is built"
echo ""
echo "To enter the control container:"
echo "  sudo docker exec -it control bash"
echo ""
echo "To stop the control container:"
echo "  sudo docker stop control"
