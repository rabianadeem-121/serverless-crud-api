// __tests__/errors.test.js
require('dotenv').config(); // loads your .env before tests
const { handler } = require('../index'); // adjust path if your Lambda file is named differently

describe('Error handling tests', () => {

  test('GET /users/:id returns 404 if user does not exist', async () => {
    const event = {
      httpMethod: 'GET',
      pathParameters: { id: '999999' } // use a non-existing user ID
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(404);
    const body = JSON.parse(response.body);
    expect(body.message).toBe('User not found');
  });

  test('PUT /users/:id returns 404 if user does not exist', async () => {
    const event = {
      httpMethod: 'PUT',
      pathParameters: { id: '999999' }, // non-existing ID
      body: JSON.stringify({ name: 'Test', email: 'test@example.com' })
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(404);
    const body = JSON.parse(response.body);
    expect(body.message).toBe('User not found');
  });

  test('DELETE /users/:id returns 404 if user does not exist', async () => {
    const event = {
      httpMethod: 'DELETE',
      pathParameters: { id: '999999' } // non-existing ID
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(404);
    const body = JSON.parse(response.body);
    expect(body.message).toBe('User not found');
  });

});
