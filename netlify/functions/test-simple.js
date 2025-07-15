const express = require('express');
const serverless = require('serverless-http');

const app = express();

// Simple test route
app.get('/', (req, res) => {
  res.json({
    message: 'Simple test successful!',
    path: req.path,
    timestamp: new Date().toISOString()
  });
});

app.get('/test', (req, res) => {
  res.json({
    message: 'Test route working!',
    environment: process.env.NODE_ENV || 'development'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found in simple test',
    path: req.path,
    method: req.method
  });
});

module.exports.handler = serverless(app); 