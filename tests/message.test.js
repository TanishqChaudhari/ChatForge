jest.mock('../src/kafka/producer', () => ({
  produceMessageEvent: jest.fn().mockResolvedValue(undefined),
  connectProducer: jest.fn().mockResolvedValue(undefined),
  disconnectProducer: jest.fn().mockResolvedValue(undefined),
}));

const request = require('supertest');
const { createTestApp } = require('./testApp');
const { produceMessageEvent } = require('../src/kafka/producer');

describe('Message API', () => {
  const app = createTestApp({ withConversations: true, withMessages: true });

  async function registerUser(username, email) {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        username,
        email,
        password: 'password123',
        passwordConfirm: 'password123',
      });

    return response.body;
  }

  test('POST /api/messages should send a message in an existing conversation', async () => {
    const alice = await registerUser('message_alice', 'message_alice@test.com');
    const bob = await registerUser('message_bob', 'message_bob@test.com');

    const conversationResponse = await request(app)
      .post('/api/conversations')
      .set('Authorization', `Bearer ${alice.token}`)
      .send({ participantId: bob.user.id });

    expect(conversationResponse.statusCode).toBe(201);
    expect(conversationResponse.body.success).toBe(true);

    const conversationId = conversationResponse.body.conversation._id;

    const messageResponse = await request(app)
      .post('/api/messages')
      .set('Authorization', `Bearer ${alice.token}`)
      .send({
        conversationId,
        content: 'Hello from Jest test',
      });

    expect(messageResponse.statusCode).toBe(201);
    expect(messageResponse.body.success).toBe(true);
    expect(messageResponse.body.data.content).toBe('Hello from Jest test');
    expect(messageResponse.body.data.conversationId.toString()).toBe(conversationId);
    expect(produceMessageEvent).toHaveBeenCalledTimes(1);
  });
});
