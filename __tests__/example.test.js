// lambda.test.js
const { handler } = require('../index'); // go up one level


describe('Lambda API tests', () => {

  test('GET /users should return status 200 and a list of users', async () => {
    const event = {
      httpMethod: 'GET',
      path: '/users',
    };

    const response = await handler(event);

    // Check HTTP status
    expect(response.statusCode).toBe(200);

    // Check response body is an array (JSON parsed)
    const body = JSON.parse(response.body);
    expect(Array.isArray(body)).toBe(true);

    // Optional: check there is at least one user
    expect(body.length).toBeGreaterThan(0);
  });

});
