const request = require('supertest');
const app = require('../src/app');

describe('DevOps API - Fase 1', () => {
  test('GET / deve retornar a identificação da disciplina', async () => {
    const response = await request(app).get('/');

    expect(response.statusCode).toBe(200);
    expect(response.body.message).toBe('DevOps API funcionando');
    expect(response.body.disciplina).toBe('DevOps na Prática');
    expect(response.body.fase).toBe('Configuração e Automação Inicial');
  });

  test('GET /health deve informar que o serviço está saudável', async () => {
    const response = await request(app).get('/health');

    expect(response.statusCode).toBe(200);
    expect(response.body.status).toBe('ok');
    expect(response.body.service).toBe('devops-api-fase1');
  });

  test('GET /api/info deve apresentar as tecnologias usadas', async () => {
    const response = await request(app).get('/api/info');

    expect(response.statusCode).toBe(200);
    expect(response.body.pipeline).toBe('GitHub Actions');
    expect(response.body.testes).toBe('Jest + Supertest');
    expect(response.body.infraestrutura).toBe('Terraform + AWS EC2');
  });

  test('rota inexistente deve retornar HTTP 404', async () => {
    const response = await request(app).get('/nao-existe');

    expect(response.statusCode).toBe(404);
    expect(response.body.error).toBe('Rota não encontrada');
  });
});
