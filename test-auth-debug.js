#!/usr/bin/env node

const http = require('http');

function makeRequest() {
  const data = JSON.stringify({
    username: 'test_debug',
    email: 'debug@test.com',
    password: 'test123',
    passwordConfirm: 'test123'
  });

  const options = {
    hostname: 'localhost',
    port: 5000,
    path: '/api/auth/register',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length
    },
    timeout: 5000
  };

  const req = http.request(options, (res) => {
    let responseData = '';

    res.on('data', (chunk) => {
      responseData += chunk;
    });

    res.on('end', () => {
      console.log('Status:', res.statusCode);
      console.log('Response:', responseData);
      
      try {
        const parsed = JSON.parse(responseData);
        console.log('\nParsed response:');
        console.log(JSON.stringify(parsed, null, 2));
      } catch (e) {
        console.log('(Not JSON)');
      }
    });
  });

  req.on('error', (error) => {
    console.error('Error:', error.message);
  });

  req.on('timeout', () => {
    req.destroy();
    console.error('Request timeout');
  });

  req.write(data);
  req.end();
}

console.log('Testing /api/auth/register endpoint...\n');
makeRequest();
