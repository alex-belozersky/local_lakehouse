#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (use sudo)." >&2
  exit 1
fi

APT_OPTS="-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"

echo "Updating system packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade $APT_OPTS

echo "Installing base tools..."
apt-get install $APT_OPTS \
  ca-certificates \
  curl \
  git \
  openssl \
  lsb-release \
  apache2-utils

echo "Installing Docker (official repo)..."

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update

apt-get install $APT_OPTS \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl enable docker
systemctl start docker

TARGET_USER="${SUDO_USER:-ubuntu}"

echo "Adding $TARGET_USER to docker group..."
groupadd -f docker
usermod -aG docker "$TARGET_USER"

echo
echo "Docker installed successfully."
docker --version
docker compose version || true
echo

echo "============================================================"
echo " NEXT STEP REQUIRED:"
echo
echo "   You must LOG OUT and LOG IN again (new SSH session),"
echo "   so that user '$TARGET_USER' gets docker group permissions."
echo
echo "   Without relogin 'docker ps' will show 'permission denied'."
echo
echo "============================================================"
echo
