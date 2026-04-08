const request = require('supertest');
const { createTestApp } = require('./testApp');

describe('Auth API', () => {
  const app = createTestApp();

  test('POST /api/auth/register should create a user and return JWT', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        username: 'auth_register_user',
        email: 'auth_register_user@test.com',
        password: 'password123',
        passwordConfirm: 'password123',
      });

    expect(response.statusCode).toBe(201);
    expect(response.body.success).toBe(true);
    expect(response.body.token).toBeTruthy();
    expect(response.body.user).toMatchObject({
      username: 'auth_register_user',
      email: 'auth_register_user@test.com',
    });
  });

  test('POST /api/auth/login should authenticate user and return JWT', async () => {
    await request(app)
      .post('/api/auth/register')
      .send({
        username: 'auth_login_user',
        email: 'auth_login_user@test.com',
        password: 'password123',
        passwordConfirm: 'password123',
      });

    const response = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'auth_login_user@test.com',
        password: 'password123',
      });

    expect(response.statusCode).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.token).toBeTruthy();
    expect(response.body.user).toMatchObject({
      username: 'auth_login_user',
      email: 'auth_login_user@test.com',
    });
  });
});
