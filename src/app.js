const express = require('express');

const app = express();

app.disable('x-powered-by');
app.use(express.json());

app.get('/', (req, res) => {
  res.status(200).json({
    message: 'DevOps API funcionando',
    disciplina: 'DevOps na Prática',
    fase: 'Configuração e Automação Inicial'
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'devops-api-fase1'
  });
});

app.get('/api/info', (req, res) => {
  res.status(200).json({
    projeto: 'devops-api-fase1',
    versao: '1.0.0',
    pipeline: 'GitHub Actions',
    testes: 'Jest + Supertest',
    infraestrutura: 'Terraform + AWS EC2'
  });
});

app.use((req, res) => {
  res.status(404).json({ error: 'Rota não encontrada' });
});

module.exports = app;
