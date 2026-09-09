const app = require('./app');
const { version } = require('../package.json');

const PORT = Number(process.env.PORT) || 3000;

function log(level, msg, extra = {}) {
  console.log(JSON.stringify({ time: new Date().toISOString(), level, msg, ...extra }));
}

const server = app.listen(PORT, '0.0.0.0', () => {
  log('info', 'DevOps API iniciada', { port: PORT, version, node: process.version });
});

// Encerramento gracioso: o Docker envia SIGTERM ao parar/recriar o container.
function shutdown(signal) {
  log('info', 'Encerrando servidor', { signal });
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(1), 10000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
