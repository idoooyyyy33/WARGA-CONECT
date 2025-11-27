const http = require('http');

const adminId = '69032982c47a01ee75d7efe0';

console.log('Testing admin aktivitas API...');

// Test admin aktivitas endpoint
const options = {
  hostname: '192.168.1.5',
  port: 3000,
  path: '/api/admin/aktivitas',
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${adminId}`,
    'Content-Type': 'application/json'
  }
};

const req = http.request(options, (res) => {
  console.log(`Status: ${res.statusCode}`);
  console.log(`Headers:`, res.headers);

  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('Response:', data);
    try {
      const jsonData = JSON.parse(data);
      console.log('Parsed JSON:', JSON.stringify(jsonData, null, 2));
    } catch (e) {
      console.log('Failed to parse JSON:', e.message);
    }
  });
});

req.on('error', (e) => {
  console.error(`Problem with request: ${e.message}`);
});

req.end();
