const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const BUILD_DIR = path.join(__dirname, 'app', 'build', 'web');

const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.svg': 'image/svg+xml',
  '.woff2': 'font/woff2',
  '.woff': 'font/woff',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.wasm': 'application/wasm',
};

const server = http.createServer((req, res) => {
  let url = req.url.replace(/^\/neolog/, '') || '/';
  if (url === '/') url = '/index.html';

  const filePath = path.join(BUILD_DIR, url);
  const ext = path.extname(filePath);

  fs.readFile(filePath, (err, data) => {
    if (err) {
      // SPA fallback
      fs.readFile(path.join(BUILD_DIR, 'index.html'), (err2, html) => {
        if (err2) {
          res.writeHead(404);
          res.end('Not found');
          return;
        }
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(html);
      });
      return;
    }
    res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
    res.end(data);
  });
});

server.listen(PORT, () => {
  console.log(`NeoLog preview server running at http://localhost:${PORT}/neolog/`);
});
