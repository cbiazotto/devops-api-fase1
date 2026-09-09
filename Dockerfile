# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Estágio 1: instala somente as dependências de produção a partir do lockfile.
# ---------------------------------------------------------------------------
FROM node:22-alpine AS deps

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev --no-audit --no-fund

# ---------------------------------------------------------------------------
# Estágio 2: imagem final enxuta, executando como usuário sem privilégios.
# ---------------------------------------------------------------------------
FROM node:22-alpine AS runtime

LABEL org.opencontainers.image.title="devops-api-fase1" \
      org.opencontainers.image.description="API Node.js/Express da disciplina DevOps na Prática" \
      org.opencontainers.image.source="https://github.com/cbiazotto/devops-api-fase1" \
      org.opencontainers.image.licenses="MIT"

ENV NODE_ENV=production \
    PORT=3000

# Endurecimento: aplica as correções de segurança dos pacotes do Alpine e remove
# npm/npx/corepack, que não são necessários em tempo de execução (reduz a
# superfície de ataque e as vulnerabilidades apontadas pelo Trivy).
RUN apk upgrade --no-cache \
    && rm -rf /usr/local/lib/node_modules/npm /usr/local/lib/node_modules/corepack \
              /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src

# O usuário "node" já existe na imagem oficial; evita rodar a API como root.
USER node

EXPOSE 3000

# Healthcheck consumido pelo Docker/Compose: o container só fica "healthy"
# quando a rota /health responde.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1

CMD ["node", "src/server.js"]
