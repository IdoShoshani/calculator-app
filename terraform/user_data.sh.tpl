#!/bin/bash
set -euo pipefail

# Install Docker
apt-get update -y
apt-get install -y docker.io
systemctl enable --now docker

# Allow the ubuntu user to run Docker commands without sudo
usermod -aG docker ubuntu

# Pull and start the application container
docker pull ${docker_image}
docker run -d \
  --name calculator-app \
  --restart unless-stopped \
  -e SERVER_PORT=${app_port} \
  -p ${app_port}:${app_port} \
  ${docker_image}
