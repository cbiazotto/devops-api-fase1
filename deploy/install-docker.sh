#!/usr/bin/env bash
# Instala o Docker Engine e o plugin Docker Compose em Ubuntu (22.04/24.04).
# Usado pelo user_data do Terraform ao criar a EC2 e pode ser executado manualmente
# em qualquer servidor Ubuntu: sudo bash deploy/install-docker.sh
set -euo pipefail

if command -v docker >/dev/null 2>&1; then
  echo "Docker já instalado: $(docker --version)"
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
ARCH="$(dpkg --print-architecture)"
echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

# Permite que o usuário padrão da AMI Ubuntu use o Docker sem sudo.
if id ubuntu >/dev/null 2>&1; then
  usermod -aG docker ubuntu
fi

docker --version
docker compose version
