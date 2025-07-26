// server/index.js
const path = require('path');
const proxy = require('express-http-proxy');
const express = require('express');
var app = express();

const PROXY_URL = process.env.PROXY_URL || 'localhost:8080'
app.use('/api/distance', proxy(PROXY_URL, {
  proxyReqPathResolver: req => {
    console.log('req.baseUrl ' + req.baseUrl)
    console.log('PROXY_URL ' + PROXY_URL)
    return req.baseUrl}
}));

const PORT = process.env.PORT || 7000

app.listen(PORT, () => console.log("server started"))

app.use(express.static(path.join(__dirname, 'dist')));

app.get("/hi", (req, res) => {
  console.log("HELLO FROM /hi")
  res.sendFile(path.resolve(__dirname, 'dist', 'index.html'));
});
