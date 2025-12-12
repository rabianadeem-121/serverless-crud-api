const axios = require('axios');

const API_URL = process.env.API_URL; // Set in GitHub Actions env

describe('API Gateway integration tests', () => {

  test('GET /users returns 200 and list', async () => {
    const res = await axios.get(`${API_URL}/users`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  test('POST /users creates a user', async () => {
    const user = { name: 'Jane Doe', email: 'jane@example.com' };
    const res = await axios.post(`${API_URL}/users`, user);
    expect(res.status).toBe(201);
    expect(res.data.name).toBe(user.name);
    expect(res.data.email).toBe(user.email);
  });

  test('GET /users/:id returns 404 for non-existing user', async () => {
    try {
      await axios.get(`${API_URL}/users/999999`);
    } catch (err) {
      expect(err.response.status).toBe(404);
      expect(err.response.data.message).toBe('User not found');
    }
  });

  test('PUT /users/:id returns 404 for non-existing user', async () => {
    try {
      await axios.put(`${API_URL}/users/999999`, { name: 'Test', email: 'test@example.com' });
    } catch (err) {
      expect(err.response.status).toBe(404);
      expect(err.response.data.message).toBe('User not found');
    }
  });

  test('DELETE /users/:id returns 404 for non-existing user', async () => {
    try {
      await axios.delete(`${API_URL}/users/999999`);
    } catch (err) {
      expect(err.response.status).toBe(404);
      expect(err.response.data.message).toBe('User not found');
    }
  });

});
