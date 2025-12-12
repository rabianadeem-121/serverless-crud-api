require('dotenv').config(); // loads local .env if available
const { handler } = require('../index');

describe('POST /users endpoint', () => {
  test('should create a new user and return status 201', async () => {
    const event = {
      httpMethod: 'POST',
      path: '/users',
      body: JSON.stringify({ name: 'John Doe', email: 'john@example.com' }),
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(201);

    const body = JSON.parse(response.body);
    expect(body.name).toBe('John Doe');
    expect(body.email).toBe('john@example.com');
    expect(body.id).toBeDefined();
  });
});

