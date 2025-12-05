#!/bin/bash

# Docker Reinstall Script
# This script removes existing Docker installation and installs vulnerable version
# WARNING: This installs Docker 18.09.0 which is vulnerable to CVE-2019-5736

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root or with sudo"
    exit 1
fi

# Confirmation prompt
print_warning "This script will:"
echo "  1. Remove existing Docker installation"
echo "  2. Install Docker 18.09.0 (VULNERABLE to CVE-2019-5736)"
echo ""


# Step 1: Stop Docker services
print_info "[$(date)] 🔴 Stopping Docker services..." >> /var/log/falco-actions.log
systemctl stop docker.socket 2>/dev/null || true
systemctl stop docker 2>/dev/null || true
systemctl stop containerd 2>/dev/null || true

# Step 2: Remove existing Docker installation
print_info "[$(date)] 🔴 Removing existing Docker packages..." >> /var/log/falco-actions.log
dpkg --purge docker-ce docker-ce-cli containerd.io runc 2>/dev/null || true
dpkg --purge docker docker-engine docker.io 2>/dev/null || true

# Step 3: Remove Docker binaries
print_info "[$(date)] 🔴 Removing Docker binaries..." >> /var/log/falco-actions.log
rm -f /usr/bin/docker
rm -f /usr/bin/dockerd
rm -f /usr/bin/docker-containerd*
rm -f /usr/bin/runc

# should change this path when needed - maybe change vm maybe change dir.
SEARCH_DIR="~/falco"  
# Step 4: Remove Docker data directories
print_info "[$(date)] 📁  Removing Docker data directories..."
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
rm -rf /etc/docker

# Step 5: Check if .deb files exist
DEB_FILES=(
    "$SEARCH_DIR/containerd.io_1.2.0-1_amd64.deb"
    "$SEARCH_DIR/docker-ce-cli_18.09.0~3-0~ubuntu-bionic_amd64.deb"
    "$SEARCH_DIR/docker-ce_18.09.0~3-0~ubuntu-xenial_amd64.deb"
)

print_info "[$(date)] 📁 Checking for required .deb files..."
missing_files=0
for deb_file in "${DEB_FILES[@]}"; do
    if [ ! -f "$deb_file" ]; then
        print_error "Missing file: $deb_file"
        missing_files=$((missing_files + 1))
    else
        print_info "Found: $deb_file"
    fi
done

if [ $missing_files -gt 0 ]; then
    print_error "[$(date)] ⚠️ $missing_files required .deb file(s) missing" >> /var/log/falco-actions.log
    print_info "Please download the required files to the current directory"
    exit 1
fi

# Step 6: Install vulnerable Docker version
print_info "Installing containerd.io 1.2.0..."
dpkg -i containerd.io_1.2.0-1_amd64.deb

print_info "Installing docker-ce-cli 18.09.0..."
dpkg -i docker-ce-cli_18.09.0~3-0~ubuntu-bionic_amd64.deb

print_info "Installing docker-ce 18.09.0..."
dpkg -i docker-ce_18.09.0~3-0~ubuntu-xenial_amd64.deb

# Step 7: Fix any dependency issues
print_info "Fixing any dependency issues..."
apt-get install -f -y || true

# Step 8: Start Docker service
print_info "[$(date)] 🔧 Starting Docker service..." >> /var/log/falco-actions.log
systemctl daemon-reload
systemctl start docker
systemctl enable docker

# Step 9: Verify installation
print_info "Verifying Docker installation..."
if docker --version; then
    print_info "[$(date)] ✅ Docker installed successfully!" >> /var/log/falco-actions.log
    docker --version
    
    # Check runc version
    print_info "Checking runc version..."
    docker run --rm alpine sh -c "cat /proc/self/exe" > /tmp/runc_check 2>/dev/null || true
    if [ -f /tmp/runc_check ]; then
        print_warning "System is vulnerable to CVE-2019-5736"
    fi
    rm -f /tmp/runc_check
else
    print_error "[$(date)] ⚠️ Docker installation verification failed" >> /var/log/falco-actions.log
    exit 1
fi

# Step 10: Security warning
echo ""
print_warning "============================================"
print_warning "SECURITY WARNING"

print_warning "============================================"
echo "This Docker version is vulnerable to CVE-2019-5736"
echo "Only use this installation for testing purposes in an isolated environment"
echo "DO NOT use in production!"
print_warning "============================================"

print_info "Installation complete!"
