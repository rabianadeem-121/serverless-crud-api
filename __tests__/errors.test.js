require('dotenv').config(); // loads local .env if available
const { handler } = require('../index'); // adjust path if needed

describe('Error handling tests', () => {

  test('GET /users/:id returns 404 if user does not exist', async () => {
    const event = {
      httpMethod: 'GET',
      pathParameters: { id: '999999' } // non-existing user ID
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(404);
    const body = JSON.parse(response.body);
    expect(body.message).toBe('User not found');
  });

  test('PUT /users/:id returns 404 if user does not exist', async () => {
    const event = {
      httpMethod: 'PUT',
      pathParameters: { id: '999999' },
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
      pathParameters: { id: '999999' }
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(404);
    const body = JSON.parse(response.body);
    expect(body.message).toBe('User not found');
  });

});
