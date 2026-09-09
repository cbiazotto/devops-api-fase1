#!/usr/bin/env bash
# Volta a API para a última versão que passou no deploy anterior.
# Uso: bash deploy/rollback.sh
set -euo pipefail

cd "$(dirname "$0")/.."

PREVIOUS_FILE=".deploy-state.previous"

if [ ! -f "$PREVIOUS_FILE" ]; then
  echo "Nenhuma versão anterior registrada em ${PREVIOUS_FILE}; nada a fazer."
  exit 1
fi

PREVIOUS="$(cat "$PREVIOUS_FILE")"
echo "==> Rollback para ${PREVIOUS}"
exec bash deploy/deploy.sh "$PREVIOUS"
