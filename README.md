# DevOps API — Fases 1 e 2

Projeto acadêmico da disciplina **DevOps na Prática**.

- **Fase 1 — Configuração e Automação Inicial:** aplicação versionada, pipeline de Integração Contínua (CI) e Infraestrutura como Código (IaC) com Terraform.
- **Fase 2 — Entrega Contínua, Monitoramento e Segurança:** pipeline de Entrega Contínua (CD), containerização com Docker, orquestração com Docker Compose, scripts de deploy, logs estruturados, métricas Prometheus e verificações de segurança.

Repositório: https://github.com/cbiazotto/devops-api-fase1

## Fluxo DevOps implementado

```mermaid
flowchart LR
    Dev[Desenvolvedor<br/>git push / pull request] --> CI

    subgraph CI["CI - Build, Testes e Validação IaC"]
        direction TB
        C1[npm ci + npm audit] --> C2[npm run build] --> C3[npm test<br/>Jest + Supertest]
        C3 --> C4[docker build + smoke test]
        T1[terraform fmt -check] --> T2[terraform init] --> T3[terraform validate]
    end

    CI -- "sucesso na main" --> CD

    subgraph CD["CD - Entrega Contínua"]
        direction TB
        D1[Build da imagem Docker] --> D2[Push no GHCR<br/>tags sha-xxxxxxx e latest]
        D2 --> D3[Scan Trivy<br/>HIGH/CRITICAL]
        D3 --> D4[Staging no runner:<br/>docker compose + smoke test + Prometheus]
        D4 --> D5{DEPLOY_HOST<br/>configurado?}
        D5 -- sim --> D6[Produção: SSH na EC2<br/>deploy/deploy.sh]
        D5 -- não --> D7[Job ignorado]
    end

    D6 --> EC2[(EC2 Ubuntu<br/>Docker + Compose<br/>API na porta 3000)]
    TF[Terraform apply<br/>VPC padrão + SG + EC2] -. provisiona .-> EC2
    EC2 --> Logs[Logs JSON<br/>docker compose logs]
    EC2 --> Metrics[/metrics<br/>Prometheus]
```

## Estrutura do projeto

```text
.
├── .github/workflows/
│   ├── ci.yml                  # CI: audit, build, testes, imagem Docker, validação Terraform
│   └── cd.yml                  # CD: build/push GHCR, Trivy, staging, produção (EC2)
├── src/
│   ├── app.js                  # Rotas Express, logging JSON e /metrics
│   └── server.js               # Inicialização e encerramento gracioso (SIGTERM)
├── tests/
│   └── app.test.js             # 9 testes Jest + Supertest
├── deploy/
│   ├── deploy.sh               # Deploy por container com smoke test e rollback automático
│   ├── rollback.sh             # Volta para a versão anterior
│   └── install-docker.sh       # Instala Docker Engine + Compose em Ubuntu
├── scripts/
│   └── smoke-test.sh           # Verifica os endpoints de uma instância em execução
├── monitoring/
│   └── prometheus.yml          # Prometheus coletando /metrics da API
├── terraform/
│   ├── providers.tf            # Terraform >= 1.5, provider AWS ~> 5.0
│   ├── variables.tf            # região, projeto, instância, porta, repositório, imagem
│   ├── main.tf                 # VPC/subnet/AMI (data), Security Group, EC2 com Docker
│   ├── outputs.tf              # instance_id, public_ip, application_url, security_group_id, container_image
│   └── terraform.tfvars.example
├── Dockerfile                  # Imagem multi-stage, usuário sem privilégios, HEALTHCHECK
├── .dockerignore
├── docker-compose.yml          # Serviço api (+ perfil monitoring com Prometheus)
├── package.json / package-lock.json
└── README.md
```

## Aplicação

API em **Node.js 22 + Express 4**. Todas as respostas são JSON, inclusive o erro 404.

| Método | Endpoint | Finalidade |
|---|---|---|
| GET | `/` | Identificação da aplicação e da fase |
| GET | `/health` | Health check: status, versão, uptime e timestamp (usado pelo Docker `HEALTHCHECK`) |
| GET | `/api/info` | Tecnologias usadas no projeto |
| GET | `/metrics` | Métricas no formato Prometheus (requisições por rota/status, uptime, memória) |

Cada requisição gera uma linha de log JSON em stdout (método, caminho, status, duração em ms), capturada pelo Docker.

### Executar localmente sem Docker

Requer Node.js 22+.

```bash
npm ci
npm start
```

A API responde em http://localhost:3000.

### Build, testes e auditoria

```bash
npm run build      # validação sintática dos arquivos JS
npm test           # 9 testes automatizados (Jest + Supertest)
npm run audit      # npm audit, falha em vulnerabilidades HIGH/CRITICAL
```

## Containerização (Docker)

O [Dockerfile](Dockerfile) usa build multi-stage:

1. **deps:** `node:22-alpine`, instala somente dependências de produção com `npm ci --omit=dev`.
2. **runtime:** copia `node_modules` e `src/`, define `NODE_ENV=production`, executa como usuário `node` (sem root), expõe a porta 3000 e declara um `HEALTHCHECK` em `/health`.

```bash
npm run docker:build                    # docker build -t devops-api-fase1:local .
docker run -d -p 3000:3000 devops-api-fase1:local
npm run smoke                           # bash scripts/smoke-test.sh http://localhost:3000
```

## Orquestração (Docker Compose)

O [docker-compose.yml](docker-compose.yml) descreve o serviço `api` com healthcheck, `restart: unless-stopped`, sistema de arquivos somente leitura, `no-new-privileges` e rotação de logs. O perfil `monitoring` adiciona um Prometheus que coleta `/metrics`.

```bash
docker compose up --build -d                      # constrói e sobe a API
docker compose --profile monitoring up -d         # API + Prometheus (http://localhost:9090)
docker compose logs -f api                        # logs JSON da API
docker compose down                               # encerra
```

Para usar a imagem publicada em vez de construir localmente:

```bash
IMAGE=ghcr.io/cbiazotto/devops-api-fase1:latest docker compose up -d --no-build
```

## Pipeline de Integração Contínua (CI)

Arquivo: `.github/workflows/ci.yml`. Executa em `push` para `main` e `develop`, em `pull_request` para `main` e manualmente.

| Job | Etapas |
|---|---|
| Build e testes automatizados | checkout → Node.js 22 com cache npm → `npm ci` → `npm audit --audit-level=high` → `npm run build` → `npm test` |
| Construir e testar a imagem Docker | `docker build` → `docker run` → `scripts/smoke-test.sh` → logs do container |
| Validar Infraestrutura como Código | Terraform 1.7.5 → `terraform fmt -check` → `terraform init -backend=false` → `terraform validate` |

## Pipeline de Entrega Contínua (CD)

Arquivo: `.github/workflows/cd.yml`. Disparado automaticamente pelo evento `workflow_run` quando o CI termina **com sucesso** na `main`; também aceita execução manual.

| Job | O que faz |
|---|---|
| Build e publicação da imagem Docker | Constrói a imagem do commit aprovado e publica no **GitHub Container Registry** com as tags `sha-<7 caracteres>` e `latest`. Roda o **Trivy**: relatório de vulnerabilidades HIGH/CRITICAL e bloqueio se houver CRITICAL com correção disponível. |
| Deploy em staging e smoke test | No próprio runner, sobe a imagem publicada com `docker compose --profile monitoring up -d --wait`, executa o smoke test, confirma que o Prometheus está coletando `/metrics` e exibe os logs JSON. Ambiente `staging` do GitHub. |
| Deploy em produção (EC2 via SSH) | Executa somente se a variável `DEPLOY_HOST` estiver definida. Conecta por SSH, faz checkout do commit aprovado e roda `deploy/deploy.sh` com a imagem publicada. Depois executa o smoke test externo. Ambiente `production` do GitHub, onde é possível exigir aprovação manual. |

### Configurar o deploy em produção

1. Provisionar o servidor (ver Terraform abaixo) ou usar qualquer Ubuntu com o repositório clonado em `/opt/devops-api` e Docker instalado (`sudo bash deploy/install-docker.sh`).
2. No GitHub, em *Settings → Secrets and variables → Actions*:
   - **Variables:** `DEPLOY_HOST` (IP ou DNS público), opcionalmente `DEPLOY_USER` (padrão `ubuntu`) e `DEPLOY_PORT` (padrão 22).
   - **Secrets:** `DEPLOY_SSH_KEY` (chave privada com acesso ao servidor).
3. Em *Settings → Environments → production*, opcionalmente exigir revisores para aprovar cada deploy.
4. Tornar o pacote `devops-api-fase1` público em *Packages → Package settings → Change visibility*, para que o servidor consiga fazer `docker pull` sem token.

## Scripts de deploy

| Script | Uso |
|---|---|
| `deploy/deploy.sh <imagem>` | `docker compose pull` → `docker compose up -d --no-build` → smoke test. Se passar, registra a imagem em `.deploy-state`; se falhar, restaura a imagem anterior automaticamente. |
| `deploy/rollback.sh` | Reexecuta o deploy com a imagem registrada em `.deploy-state.previous`. |
| `deploy/install-docker.sh` | Instala Docker Engine e Docker Compose em Ubuntu (usado pelo `user_data` da EC2). |
| `scripts/smoke-test.sh [url]` | Aguarda `/health` e valida `/`, `/health`, `/api/info`, `/metrics` e o 404. |

Exemplo no servidor:

```bash
cd /opt/devops-api
bash deploy/deploy.sh ghcr.io/cbiazotto/devops-api-fase1:sha-1a2b3c4
bash deploy/rollback.sh
```

## Monitoramento e logging

- **Logs estruturados:** uma linha JSON por requisição (`time`, `level`, `method`, `path`, `status`, `duration_ms`) e eventos de início/encerramento. Lidos com `docker compose logs -f api`; prontos para envio ao CloudWatch Logs ou ELK.
- **Métricas:** `/metrics` expõe `http_requests_total{method,route,status}`, `process_uptime_seconds`, `process_resident_memory_bytes` e `app_info`. O Prometheus do perfil `monitoring` coleta a cada 15 s.
- **Health check:** `HEALTHCHECK` no Dockerfile e no Compose; o CD só considera o deploy pronto quando o container fica `healthy`.

## Segurança

- `npm audit --audit-level=high` no CI e dependências fixadas pelo `package-lock.json`.
- Scan da imagem com Trivy no CD; vulnerabilidades CRITICAL com correção disponível bloqueiam a entrega.
- Imagem sem root (`USER node`), sem dependências de desenvolvimento, `X-Powered-By` desabilitado.
- Container com `read_only`, `no-new-privileges` e rotação de logs.
- Workflows com permissões mínimas (`contents: read`, `packages: write` apenas no CD); credenciais de produção somente em GitHub Secrets.
- Security Group libera apenas a porta da aplicação.

## Infraestrutura como Código (Terraform)

Os arquivos estão em `terraform/`. A EC2 Ubuntu 22.04 é criada na VPC padrão com um Security Group que libera a porta 3000. O `user_data` clona o repositório em `/opt/devops-api`, instala o Docker com `deploy/install-docker.sh` e executa `deploy/deploy.sh` com a imagem definida em `container_image` (padrão `ghcr.io/cbiazotto/devops-api-fase1:latest`).

```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply      # somente com credenciais AWS/AWS Academy configuradas
terraform destroy    # ao encerrar o laboratório
```

Saídas: `instance_id`, `public_ip`, `application_url`, `security_group_id` e `container_image`.

> Em ambiente acadêmico AWS, confira os recursos permitidos e destrua os recursos quando não estiver usando.
