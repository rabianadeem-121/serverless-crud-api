// error.test.js
const { handler } = require('../index'); // go up one level


describe('Error handling tests', () => {

  test('GET /users/:id returns 404 if user does not exist', async () => {
    const event = {
      httpMethod: 'GET',
      path: '/users/9999'
    };

    const response = await handler(event);

    expect(response.statusCode).toBe(404);

    const body = JSON.parse(response.body);
    expect(body.message).toBe('User not found');
  });

});
