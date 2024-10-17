import express from 'express';
import client from 'prom-client';

const app = express();
const collectDefaultMetrics = client.collectDefaultMetrics;
const Registry = client.Registry;
const register = new Registry();

collectDefaultMetrics({ register });

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

export function startMetricsServer() {
  const port = 8080;
  app.listen(port, () => {
    console.log(`Metrics server listening on port ${port}`);
  });
}