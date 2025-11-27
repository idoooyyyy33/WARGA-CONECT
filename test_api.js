const http = require('http');

const testStatsEndpoint = () => {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/admin/stats',
      method: 'GET',
      headers: {
        'Authorization': 'Bearer 69032982c47a01ee75d7efe0',
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      console.log('Status:', res.statusCode);
      console.log('Headers:', JSON.stringify(res.headers, null, 2));

      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const jsonData = JSON.parse(data);
          console.log('Response:', JSON.stringify(jsonData, null, 2));
          resolve(jsonData);
        } catch (e) {
          console.log('Raw Response:', data);
          resolve(data);
        }
      });
    });

    req.on('error', (e) => {
      console.error('Error:', e.message);
      reject(e);
    });

    req.setTimeout(5000, () => {
      console.log('Request timeout');
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.end();
  });
};

const testAktivitasEndpoint = () => {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/admin/aktivitas',
      method: 'GET',
      headers: {
        'Authorization': 'Bearer 69032982c47a01ee75d7efe0',
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      console.log('Aktivitas Status:', res.statusCode);

      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const jsonData = JSON.parse(data);
          console.log('Aktivitas Response:', JSON.stringify(jsonData, null, 2));
          resolve(jsonData);
        } catch (e) {
          console.log('Aktivitas Raw Response:', data);
          resolve(data);
        }
      });
    });

    req.on('error', (e) => {
      console.error('Aktivitas Error:', e.message);
      reject(e);
    });

    req.setTimeout(5000, () => {
      console.log('Aktivitas Request timeout');
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.end();
  });
};

async function runTests() {
  try {
    console.log('Testing admin stats endpoint...');
    await testStatsEndpoint();

    console.log('\nTesting admin aktivitas endpoint...');
    await testAktivitasEndpoint();

  } catch (error) {
    console.error('Test failed:', error.message);
  }
}

runTests();
