const Message = require('../models/Message');
const Conversation = require('../models/Conversation');
const { produceMessageEvent } = require('../kafka/producer');

// @desc    Send a message
// @route   POST /api/messages
// @access  Private
exports.sendMessage = async (req, res) => {
  try {
    const { conversationId, content } = req.body;
    const senderId = req.user.id;

    // Validation
    if (!conversationId || !content) {
      return res.status(400).json({
        success: false,
        message: 'Please provide conversationId and content',
      });
    }

    // Check if conversation exists
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found',
      });
    }

    // Check if user is participant
    const isParticipant = conversation.participants.some(
      (p) => p.toString() === senderId
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You are not a participant in this conversation',
      });
    }

    // Create message
    const message = await Message.create({
      conversationId,
      senderId,
      content,
      status: 'sent',
    });

    // Populate sender details
    await message.populate('senderId', '_id username email');

    // Update conversation lastMessage
    await Conversation.findByIdAndUpdate(
      conversationId,
      { lastMessage: message._id, updatedAt: new Date() },
      { new: true }
    );

    // Produce message event to Kafka for event streaming
    try {
      await produceMessageEvent(message);
    } catch (kafkaErr) {
      console.error('Kafka producer error (non-blocking):', kafkaErr.message);
      // Don't fail the REST request, just log the error
    }

    res.status(201).json({
      success: true,
      message: 'Message sent successfully',
      data: message,
    });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to send message',
    });
  }
};

// @desc    Mark message as read
// @route   PATCH /api/messages/:id/read
// @access  Private
exports.markMessageAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Find message
    const message = await Message.findById(id);
    if (!message) {
      return res.status(404).json({
        success: false,
        message: 'Message not found',
      });
    }

    // Check if user is the receiver
    const conversation = await Conversation.findById(message.conversationId);
    const isParticipant = conversation.participants.some(
      (p) => p.toString() === userId
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You cannot mark this message as read',
      });
    }

    // Update message status
    message.status = 'read';
    message.readAt = new Date();
    await message.save();

    res.status(200).json({
      success: true,
      message: 'Message marked as read',
      data: message,
    });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to mark message as read',
    });
  }
};

// @desc    Update message status
// @route   PATCH /api/messages/:id/status
// @access  Private
exports.updateMessageStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const userId = req.user.id;

    // Validate status
    const validStatuses = ['sent', 'delivered', 'read'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Status must be one of: ${validStatuses.join(', ')}`,
      });
    }

    // Find message
    const message = await Message.findById(id);
    if (!message) {
      return res.status(404).json({
        success: false,
        message: 'Message not found',
      });
    }

    // Check permissions
    const conversation = await Conversation.findById(message.conversationId);
    const isParticipant = conversation.participants.some(
      (p) => p.toString() === userId
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You cannot update this message status',
      });
    }

    // Update status
    message.status = status;
    if (status === 'delivered') {
      message.deliveredAt = new Date();
    } else if (status === 'read') {
      message.readAt = new Date();
    }
    await message.save();

    res.status(200).json({
      success: true,
      message: 'Message status updated',
      data: message,
    });
  } catch (error) {
    console.error('Update status error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to update message status',
    });
  }
};

// @desc    Get all messages in a conversation
// @route   GET /api/messages/:conversationId
// @access  Private
exports.getMessages = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // Check if conversation exists and user is participant
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found',
      });
    }

    const isParticipant = conversation.participants.some(
      (p) => p.toString() === userId
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You are not a participant in this conversation',
      });
    }

    // Get messages
    const totalMessages = await Message.countDocuments({
      conversationId,
    });

    const messages = await Message.find({ conversationId })
      .populate('senderId', '_id username email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    messages.reverse(); // Chronological order

    res.status(200).json({
      success: true,
      count: messages.length,
      pagination: {
        total: totalMessages,
        page,
        pages: Math.ceil(totalMessages / limit),
        limit,
      },
      messages,
    });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch messages',
    });
  }
};
