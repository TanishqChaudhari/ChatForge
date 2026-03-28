const express = require('express');
const {
  sendMessage,
  markMessageAsRead,
  updateMessageStatus,
  getMessages,
} = require('../controllers/messageController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// POST - Send a message
router.post('/', authMiddleware, sendMessage);

// GET - Get all messages in a conversation
router.get('/:conversationId', authMiddleware, getMessages);

// PATCH - Mark message as read
router.patch('/:id/read', authMiddleware, markMessageAsRead);

// PATCH - Update message status
router.patch('/:id/status', authMiddleware, updateMessageStatus);

module.exports = router;
