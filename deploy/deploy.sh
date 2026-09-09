#!/usr/bin/env bash
# Deploy da API em um host com Docker, a partir da imagem publicada no GHCR.
#
# Uso (a partir de qualquer diretório; o script muda para a raiz do repositório):
#   bash deploy/deploy.sh ghcr.io/cbiazotto/devops-api-fase1:sha-abc1234
#   IMAGE=ghcr.io/cbiazotto/devops-api-fase1:latest bash deploy/deploy.sh
#
# Fluxo: pull da imagem -> recria o container via Docker Compose -> aguarda o
# healthcheck e roda o smoke test -> registra a versão para rollback.
# Se o smoke test falhar, a versão anterior é restaurada automaticamente.
set -euo pipefail

cd "$(dirname "$0")/.."

IMAGE="${1:-${IMAGE:-ghcr.io/cbiazotto/devops-api-fase1:latest}}"
PORT="${PORT:-3000}"
BASE_URL="${BASE_URL:-http://localhost:${PORT}}"
STATE_FILE=".deploy-state"              # imagem em execução
PREVIOUS_FILE=".deploy-state.previous"  # imagem anterior (alvo do rollback)

echo "==> Deploy de ${IMAGE} (porta ${PORT})"

CURRENT=""
if [ -f "$STATE_FILE" ]; then
  CURRENT="$(cat "$STATE_FILE")"
fi

echo "==> Baixando a imagem"
IMAGE="$IMAGE" PORT="$PORT" docker compose pull api

echo "==> Recriando o container"
IMAGE="$IMAGE" PORT="$PORT" docker compose up -d --no-build --remove-orphans api

if bash scripts/smoke-test.sh "$BASE_URL"; then
  if [ -n "$CURRENT" ] && [ "$CURRENT" != "$IMAGE" ]; then
    echo "$CURRENT" > "$PREVIOUS_FILE"
  fi
  echo "$IMAGE" > "$STATE_FILE"
  docker image prune -f >/dev/null
  echo "==> Deploy concluído: ${IMAGE}"
  IMAGE="$IMAGE" PORT="$PORT" docker compose ps api
  exit 0
fi

echo "!!! Smoke test falhou para ${IMAGE}"
IMAGE="$IMAGE" PORT="$PORT" docker compose logs --tail=50 api || true

if [ -n "$CURRENT" ] && [ "$CURRENT" != "$IMAGE" ]; then
  echo "==> Rollback automático para ${CURRENT}"
  IMAGE="$CURRENT" PORT="$PORT" docker compose up -d --no-build --remove-orphans api
  bash scripts/smoke-test.sh "$BASE_URL" && echo "==> Versão anterior restaurada"
fi

exit 1
