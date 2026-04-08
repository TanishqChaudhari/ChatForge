const express = require('express');

function createTestApp(options = {}) {
  const { withConversations = false, withMessages = false } = options;
  const app = express();
  const authRoutes = require('../src/routes/auth');

  app.use(express.json());
  app.use('/api/auth', authRoutes);

  if (withConversations) {
    const conversationRoutes = require('../src/routes/conversations');
    app.use('/api/conversations', conversationRoutes);
  }

  if (withMessages) {
    const messageRoutes = require('../src/routes/messages');
    app.use('/api/messages', messageRoutes);
  }

  return app;
}

module.exports = {
  createTestApp,
};
