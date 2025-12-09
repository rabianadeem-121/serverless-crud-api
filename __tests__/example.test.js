// __tests__/example.test.js
const { handler } = require('../index');

describe('Lambda API tests', () => {
  test('GET /users should return status 200 and a list of users', async () => {
    const event = {
      httpMethod: 'GET',
      path: '/users',
    };

    // Set RDS credentials from environment variables
    process.env.DB_HOST = process.env.DB_HOST;
    process.env.DB_USER = process.env.DB_USER;
    process.env.DB_PASSWORD = process.env.DB_PASSWORD;
    process.env.DB_NAME = process.env.DB_NAME;
    process.env.DB_PORT = process.env.DB_PORT || 5432;

    const response = await handler(event);

    expect(response.statusCode).toBe(200);

    const body = JSON.parse(response.body);
    expect(Array.isArray(body)).toBe(true);
    expect(body.length).toBeGreaterThanOrEqual(0);
  });
});

