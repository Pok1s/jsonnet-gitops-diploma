'use strict';

const express = require('express');
const helmet = require('helmet');

function buildMetadata() {
  return {
    name: process.env.APP_NAME || 'diploma-demo-web',
    version: process.env.APP_VERSION || 'local',
    environment: process.env.APP_ENV || 'local',
    deploymentTimestamp: process.env.DEPLOYMENT_TIMESTAMP || new Date().toISOString(),
    commitSha: process.env.GIT_SHA || 'local'
  };
}

function createApp() {
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet());

  app.get('/healthz', (_req, res) => {
    res.status(200).json({ status: 'ok' });
  });

  app.get('/readyz', (_req, res) => {
    res.status(200).json({ status: 'ready' });
  });

  app.get('/api/info', (_req, res) => {
    res.status(200).json(buildMetadata());
  });

  app.get('/', (_req, res) => {
    const metadata = buildMetadata();
    res.type('html').send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${metadata.name}</title>
  <style>
    :root {
      color-scheme: light dark;
      --bg: #f7f8fb;
      --panel: #ffffff;
      --text: #18202f;
      --muted: #5d6678;
      --accent: #0f766e;
      --border: #d9dee8;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #111827;
        --panel: #182132;
        --text: #f5f7fb;
        --muted: #b6c0d4;
        --accent: #2dd4bf;
        --border: #303a4f;
      }
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      background: var(--bg);
      color: var(--text);
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }
    main {
      width: min(720px, calc(100vw - 32px));
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 32px;
      box-shadow: 0 18px 48px rgba(15, 23, 42, 0.12);
    }
    h1 { margin: 0 0 8px; font-size: clamp(28px, 4vw, 44px); letter-spacing: 0; }
    p { margin: 0 0 28px; color: var(--muted); line-height: 1.6; }
    dl { margin: 0; display: grid; gap: 14px; }
    .row { display: grid; grid-template-columns: 180px 1fr; gap: 16px; padding: 14px 0; border-top: 1px solid var(--border); }
    dt { color: var(--muted); }
    dd { margin: 0; font-weight: 700; overflow-wrap: anywhere; }
    .badge { display: inline-block; color: #042f2e; background: var(--accent); border-radius: 999px; padding: 4px 10px; font-size: 13px; font-weight: 800; }
    @media (max-width: 540px) {
      main { padding: 24px; }
      .row { grid-template-columns: 1fr; gap: 4px; }
    }
  </style>
</head>
<body>
  <main>
    <span class="badge">GitOps Demo</span>
    <h1>${metadata.name}</h1>
    <p>Application deployed automatically through GitHub Actions, Azure Container Registry, Argo CD and Jsonnet-generated Kubernetes manifests.</p>
    <dl>
      <div class="row"><dt>Version</dt><dd>${metadata.version}</dd></div>
      <div class="row"><dt>Environment</dt><dd>${metadata.environment}</dd></div>
      <div class="row"><dt>Deployment timestamp</dt><dd>${metadata.deploymentTimestamp}</dd></div>
      <div class="row"><dt>Git SHA</dt><dd>${metadata.commitSha}</dd></div>
    </dl>
  </main>
</body>
</html>`);
  });

  return app;
}

if (require.main === module) {
  const port = Number(process.env.PORT || 8080);
  createApp().listen(port, '0.0.0.0', () => {
    console.log(`diploma-demo-web listening on ${port}`);
  });
}

module.exports = { createApp, buildMetadata };

