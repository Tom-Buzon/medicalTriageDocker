#!/usr/bin/env bash

set -euo pipefail

# This script is designed for the EC2 "User data" field on Ubuntu 24.04.
# EC2 runs it as root once, during the first boot.

TARGET_USER="ubuntu"
REPOSITORY_URL="https://github.com/Tom-Buzon/medicalTriageDocker.git"
PROJECT_DIR="/home/${TARGET_USER}/medicalTriageDocker"
LOG_FILE="/var/log/medical-triage-bootstrap.log"

exec > >(tee -a "${LOG_FILE}" | logger -t medical-triage-bootstrap -s 2>/dev/console) 2>&1

echo "Starting MedicalDocker EC2 bootstrap"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    curl \
    git \
    openssl

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

. /etc/os-release

tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

systemctl enable --now docker
usermod -aG docker "${TARGET_USER}"

if [[ ! -d "${PROJECT_DIR}/.git" ]]; then
    runuser -u "${TARGET_USER}" -- \
        git clone "${REPOSITORY_URL}" "${PROJECT_DIR}"
fi

chown -R "${TARGET_USER}:${TARGET_USER}" "${PROJECT_DIR}"

echo "Bootstrap complete"
echo "Project directory: ${PROJECT_DIR}"
echo "Reconnect the SSH session so Docker group membership is refreshed."
