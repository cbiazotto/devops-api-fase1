#!/usr/bin/env bash
# Teste de fumaça: valida os endpoints principais de uma instância da API em execução.
#
# Uso: bash scripts/smoke-test.sh [URL_BASE]      (padrão: http://localhost:3000)
# Variáveis: SMOKE_RETRIES (tentativas de espera pelo /health, padrão 20)
set -euo pipefail

BASE_URL="${1:-http://localhost:3000}"
RETRIES="${SMOKE_RETRIES:-20}"
BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT

echo "==> Aguardando ${BASE_URL}/health responder..."
for attempt in $(seq 1 "$RETRIES"); do
  if curl -fsS "${BASE_URL}/health" >/dev/null 2>&1; then
    break
  fi
  if [ "$attempt" -eq "$RETRIES" ]; then
    echo "ERRO: a aplicação não respondeu após ${RETRIES} tentativas"
    exit 1
  fi
  sleep 2
done

# check <caminho> <status esperado> <trecho esperado no corpo>
check() {
  local path="$1" expected="$2" needle="$3" status
  status="$(curl -sS -o "$BODY_FILE" -w '%{http_code}' "${BASE_URL}${path}")"
  if [ "$status" != "$expected" ] || ! grep -q -- "$needle" "$BODY_FILE"; then
    echo "FALHOU: ${path} (status ${status}, esperado ${expected})"
    echo "Corpo: $(cat "$BODY_FILE")"
    exit 1
  fi
  echo "OK: ${path} -> ${status}"
}

check "/"                 200 '"message":"DevOps API funcionando"'
check "/health"           200 '"status":"ok"'
check "/api/info"         200 '"pipeline":"GitHub Actions"'
check "/metrics"          200 'http_requests_total'
check "/rota-inexistente" 404 '"error"'

echo "==> Smoke test concluído com sucesso em ${BASE_URL}"
