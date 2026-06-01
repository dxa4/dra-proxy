const http = require('http');
const https = require('https');

const PORT = 3000;
const TARGET = process.env.TARGET_URL || 'https://api-copilot.x5.ru/aigw/v1/chat/completions';

const server = http.createServer((req, res) => {
  // CORS — разрешаем всё, включая origin: null (Figma plugin)
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, HTTP-Referer, X-Title');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  if (req.method !== 'POST') {
    res.writeHead(405);
    res.end(JSON.stringify({ error: 'Method not allowed' }));
    return;
  }

  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', () => {
    const targetUrl = new URL(TARGET);
    const options = {
      hostname: targetUrl.hostname,
      path: targetUrl.pathname,
      method: 'POST',
      rejectUnauthorized: false, // корп. сертификат X5
      headers: {
        'Content-Type': 'application/json',
        'Authorization': req.headers['authorization'] || '',
        'Content-Length': Buffer.byteLength(body),
      },
    };

    const proxyReq = https.request(options, proxyRes => {
      res.writeHead(proxyRes.statusCode, {
        'Content-Type': proxyRes.headers['content-type'] || 'text/event-stream',
        'Cache-Control': 'no-cache',
        'X-Accel-Buffering': 'no',
      });
      proxyRes.pipe(res);
    });

    proxyReq.on('error', err => {
      console.error('Proxy error:', err.message);
      res.writeHead(500);
      res.end(JSON.stringify({ error: err.message }));
    });

    proxyReq.write(body);
    proxyReq.end();
  });
});

server.listen(PORT, () => {
  console.log(`✅ Прокси запущен: http://localhost:${PORT}`);
  console.log(`→ Проксирует на: ${TARGET}`);
  console.log(`\nВ плагине укажи API URL:\nhttp://localhost:${PORT}/`);
});
