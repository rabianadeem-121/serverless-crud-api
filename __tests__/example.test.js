if (!process.env.GITHUB_ACTIONS) {
  require('dotenv').config();
}

const { handler } = require('../index');

describe('Lambda API tests', () => {
  test('GET /users should return status 200 and a list of users', async () => {
    const event = { httpMethod: 'GET', path: '/users' };

    const response = await handler(event);

    expect(response.statusCode).toBe(200);

    const body = JSON.parse(response.body);
    expect(Array.isArray(body)).toBe(true);
    expect(body.length).toBeGreaterThanOrEqual(0);
  });
});

