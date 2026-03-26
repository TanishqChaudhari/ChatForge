const express = require('express');
const {
  createOrGetConversation,
  getUserConversations,
  getConversationMessages,
  getConversation,
  deleteConversation,
} = require('../controllers/conversationController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// All conversation routes are protected
router.use(authMiddleware);

// Create or get existing conversation
router.post('/', createOrGetConversation);

// Get all conversations for current user
router.get('/', getUserConversations);

// Get single conversation
router.get('/:id', getConversation);

// Get messages from a conversation with pagination
router.get('/:id/messages', getConversationMessages);

// Delete conversation
router.delete('/:id', deleteConversation);

module.exports = router;
