// __tests__/error.test.js
const { handler } = require('../index');

describe('Error handling tests', () => {
  test('GET /users/:id returns 404 if user does not exist', async () => {
    const event = {
      httpMethod: 'GET',
      path: '/users/9999',
    };

    // Set RDS credentials
    process.env.DB_HOST = process.env.DB_HOST;
    process.env.DB_USER = process.env.DB_USER;
    process.env.DB_PASSWORD = process.env.DB_PASSWORD;
    process.env.DB_NAME = process.env.DB_NAME;
    process.env.DB_PORT = process.env.DB_PORT || 5432;

    const response = await handler(event);

    expect(response.statusCode).toBe(404);

    const body = JSON.parse(response.body);
    expect(body.message).toBe('User not found');
  });
});

