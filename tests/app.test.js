const request = require('supertest');
const app = require('../src/app');
const { version } = require('../package.json');

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

describe('DevOps API - Fase 2 (containers, entrega contínua e monitoramento)', () => {
  test('GET /health deve expor versão e tempo de atividade para o healthcheck do container', async () => {
    const response = await request(app).get('/health');

    expect(response.statusCode).toBe(200);
    expect(response.body.version).toBe(version);
    expect(typeof response.body.uptime_seconds).toBe('number');
    expect(response.body.uptime_seconds).toBeGreaterThanOrEqual(0);
    expect(new Date(response.body.timestamp).toString()).not.toBe('Invalid Date');
  });

  test('GET /api/info deve descrever a versão e a estratégia de entrega em containers', async () => {
    const response = await request(app).get('/api/info');

    expect(response.body.versao).toBe(version);
    expect(response.body.container).toBe('Docker + Docker Compose');
    expect(response.body.entrega).toContain('GitHub Actions CD');
  });

  test('GET /metrics deve expor métricas no formato Prometheus', async () => {
    await request(app).get('/health');
    const response = await request(app).get('/metrics');

    expect(response.statusCode).toBe(200);
    expect(response.headers['content-type']).toContain('text/plain');
    expect(response.text).toContain('# TYPE http_requests_total counter');
    expect(response.text).toMatch(/http_requests_total\{method="GET",route="\/health",status="200"\} \d+/);
    expect(response.text).toMatch(/process_uptime_seconds \d+(\.\d+)?/);
    expect(response.text).toMatch(/process_resident_memory_bytes \d+/);
    expect(response.text).toContain(`app_info{name="devops-api-fase1",version="${version}"} 1`);
  });

  test('requisições a rotas inexistentes devem ser contadas sem criar rótulos por caminho', async () => {
    await request(app).get('/qualquer-coisa-aleatoria');
    const response = await request(app).get('/metrics');

    expect(response.text).toMatch(/http_requests_total\{method="GET",route="unmatched",status="404"\} \d+/);
    expect(response.text).not.toContain('qualquer-coisa-aleatoria');
  });

  test('a resposta não deve expor o cabeçalho X-Powered-By', async () => {
    const response = await request(app).get('/health');

    expect(response.headers['x-powered-by']).toBeUndefined();
  });
});
