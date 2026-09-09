const express = require('express');
const { name: appName, version: appVersion } = require('../package.json');

const app = express();
const startedAt = Date.now();

// Contador de requisições por método/rota/status, exposto em /metrics (formato Prometheus).
const requestsTotal = new Map();

function recordRequest(method, route, status) {
  const key = `${method}|${route}|${status}`;
  requestsTotal.set(key, (requestsTotal.get(key) || 0) + 1);
}

app.disable('x-powered-by');
app.use(express.json());

// Logging estruturado (uma linha JSON por requisição) e coleta de métricas.
// Os logs vão para stdout, de onde o Docker os captura (`docker logs`).
app.use((req, res, next) => {
  const start = process.hrtime.bigint();

  res.on('finish', () => {
    const durationMs = Number(process.hrtime.bigint() - start) / 1e6;
    const route = req.route ? req.route.path : 'unmatched';

    recordRequest(req.method, route, res.statusCode);

    if (process.env.NODE_ENV !== 'test') {
      console.log(JSON.stringify({
        time: new Date().toISOString(),
        level: res.statusCode >= 500 ? 'error' : 'info',
        msg: 'request',
        method: req.method,
        path: req.originalUrl,
        status: res.statusCode,
        duration_ms: Number(durationMs.toFixed(1))
      }));
    }
  });

  next();
});

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
    service: appName,
    version: appVersion,
    uptime_seconds: Math.round((Date.now() - startedAt) / 1000),
    timestamp: new Date().toISOString()
  });
});

app.get('/api/info', (req, res) => {
  res.status(200).json({
    projeto: appName,
    versao: appVersion,
    pipeline: 'GitHub Actions',
    testes: 'Jest + Supertest',
    infraestrutura: 'Terraform + AWS EC2',
    container: 'Docker + Docker Compose',
    entrega: 'GitHub Actions CD + GitHub Container Registry',
    monitoramento: 'Logs JSON + métricas Prometheus em /metrics'
  });
});

// Métricas no formato de exposição do Prometheus, sem dependências externas.
app.get('/metrics', (req, res) => {
  const memory = process.memoryUsage();
  const lines = [
    '# HELP http_requests_total Total de requisicoes HTTP recebidas.',
    '# TYPE http_requests_total counter'
  ];

  for (const [key, count] of requestsTotal) {
    const [method, route, status] = key.split('|');
    lines.push(`http_requests_total{method="${method}",route="${route}",status="${status}"} ${count}`);
  }

  lines.push(
    '# HELP process_uptime_seconds Tempo desde o inicio do processo, em segundos.',
    '# TYPE process_uptime_seconds gauge',
    `process_uptime_seconds ${((Date.now() - startedAt) / 1000).toFixed(3)}`,
    '# HELP process_resident_memory_bytes Memoria residente do processo, em bytes.',
    '# TYPE process_resident_memory_bytes gauge',
    `process_resident_memory_bytes ${memory.rss}`,
    '# HELP app_info Informacoes da aplicacao.',
    '# TYPE app_info gauge',
    `app_info{name="${appName}",version="${appVersion}"} 1`
  );

  res.status(200).type('text/plain; version=0.0.4').send(`${lines.join('\n')}\n`);
});

app.use((req, res) => {
  res.status(404).json({ error: 'Rota não encontrada' });
});

module.exports = app;
