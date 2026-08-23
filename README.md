# DevOps API — Fase 1

Projeto acadêmico da disciplina **DevOps na Prática**, referente à **Fase 1 — Configuração e Automação Inicial**.

O repositório demonstra três elementos principais da fase:

1. aplicação versionada em Git/GitHub;
2. pipeline de Integração Contínua com GitHub Actions, build e testes automatizados;
3. scripts de Infraestrutura como Código (IaC) usando Terraform para AWS.

## Arquitetura do projeto

```text
.
├── .github/workflows/ci.yml
├── src/
│   ├── app.js
│   └── server.js
├── tests/
│   └── app.test.js
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── docs/
│   └── EVIDENCIAS.md
├── .gitignore
├── package.json
└── README.md
```

## Aplicação

API simples em **Node.js + Express**.

### Endpoints

| Método | Endpoint | Finalidade |
|---|---|---|
| GET | `/` | Identificação da aplicação e da fase |
| GET | `/health` | Health check da aplicação |
| GET | `/api/info` | Tecnologias usadas no projeto |

## Executar localmente

Requer Node.js 20+.

```bash
npm install
npm start
```

A API ficará disponível em:

```text
http://localhost:3000
```

## Build

Neste projeto Node.js simples não existe etapa de compilação. O script de build executa uma **validação sintática** dos arquivos JavaScript:

```bash
npm run build
```

## Testes automatizados

Os testes usam **Jest + Supertest** e validam as rotas da API.

```bash
npm test
```

Para cobertura:

```bash
npm run test:coverage
```

## Pipeline de Integração Contínua

Arquivo:

```text
.github/workflows/ci.yml
```

O GitHub Actions executa automaticamente em:

- `push` nas branches `main` e `develop`;
- `pull_request` direcionado à `main`;
- execução manual com `workflow_dispatch`.

### Job 1 — Build e testes

1. checkout do código;
2. configuração do Node.js 20;
3. instalação das dependências;
4. execução do build/validação sintática;
5. execução dos testes automatizados.

### Job 2 — Terraform

1. checkout do código;
2. configuração do Terraform;
3. `terraform fmt -check`;
4. `terraform init -backend=false`;
5. `terraform validate`.

A infraestrutura não é criada automaticamente pelo CI nesta fase, evitando a necessidade de armazenar credenciais AWS no GitHub apenas para a validação acadêmica.

## Infraestrutura como Código

Os arquivos estão em `terraform/`.

A infraestrutura planejada contém:

- uso da VPC padrão da AWS;
- seleção de uma subnet da VPC padrão;
- AMI Ubuntu 22.04;
- instância Amazon EC2;
- Security Group liberando a porta TCP 3000;
- tags para identificação dos recursos;
- outputs com ID da instância, IP público, URL da aplicação e Security Group.

### Validar Terraform

```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
```

### Provisionar na AWS

Somente execute após configurar suas credenciais/laboratório AWS e conferir o plano:

```bash
terraform apply
```

Para remover os recursos e evitar consumo desnecessário:

```bash
terraform destroy
```

> Em ambiente acadêmico AWS, confira os recursos permitidos e encerre/destrua recursos quando não estiver usando.


