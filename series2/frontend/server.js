const http = require('http');
const fs = require('fs');
const path = require('path');

const port = 3000;

const mimeTypes = {
    '.html': 'text/html',
    '.js': 'application/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.svg': 'image/svg+xml',
    '.map': 'application/octet-stream'
};

const server = http.createServer((req, res) => {
    let filePath = '.' + req.url;

    // Default to main front page
    if (filePath === './') {
        filePath = './index.html';
    }

    // If someone requests /polymetric, load /polymetric/index.html
    if (fs.existsSync('.' + req.url) && fs.lstatSync('.' + req.url).isDirectory()) {
        filePath = '.' + req.url + '/index.html';
    }

    const absolutePath = path.join(__dirname, filePath);
    const extname = String(path.extname(absolutePath)).toLowerCase();
    const contentType = mimeTypes[extname] || 'application/octet-stream';

    fs.readFile(absolutePath, (error, content) => {
        if (error) {
            if (error.code === 'ENOENT') {
                res.writeHead(404, { 'Content-Type': 'text/html' });
                res.end(`<h1>404 Not Found</h1><p>${req.url} was not found.</p>`);
            } else {
                res.writeHead(500);
                res.end(`Server error: ${error.code}`);
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

server.listen(port, () => {
    console.log(`\nServer running at http://localhost:${port}`);
});
