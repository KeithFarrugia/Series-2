const http = require('http');
const fs = require('fs');
const path = require('path');

const port = 3000;

// Mapping for common MIME types
const mimeTypes = {
    '.html': 'text/html',
    '.js': 'application/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg'
};

const server = http.createServer((req, res) => {
    // Determine the file path; default to index.html for root requests
    let filePath = '.' + req.url;
    if (filePath === './') {
        filePath = './index.html';
    }

    // Resolve the full path
    const absolutePath = path.join(__dirname, filePath);
    const extname = String(path.extname(absolutePath)).toLowerCase();
    const contentType = mimeTypes[extname] || 'application/octet-stream';

    // Read the file asynchronously
    fs.readFile(absolutePath, (error, content) => {
        if (error) {
            if (error.code === 'ENOENT') {
                // File not found (404)
                res.writeHead(404, { 'Content-Type': 'text/html' });
                res.end(`<h1>404 Not Found</h1><p>The requested URL ${req.url} was not found.</p>`);
            } else {
                // Server error (500)
                res.writeHead(500);
                res.end(`Sorry, check with the site admin for error: ${error.code} ..\n`);
            }
        } else {
            // Success (200)
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

server.listen(port, () => {
    console.log(`\n-----------------------------------------`);
    console.log(`Server running at http://localhost:${port}/`);
    console.log(`Serving files from: ${__dirname}`);
    console.log(`Press Ctrl+C to stop the server.`);
    console.log(`-----------------------------------------\n`);
});