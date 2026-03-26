const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const User = require('../models/User');

// @desc    Create or get existing 1-to-1 conversation
// @route   POST /api/conversations
// @access  Private
exports.createOrGetConversation = async (req, res) => {
  try {
    const { participantId } = req.body;
    const currentUserId = req.user.id;

    // Validation
    if (!participantId) {
      return res.status(400).json({
        success: false,
        message: 'Please provide participant ID',
      });
    }

    // Check if user exists
    const participant = await User.findById(participantId);
    if (!participant) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Cannot create conversation with self
    if (currentUserId === participantId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot create conversation with yourself',
      });
    }

    // Check if conversation already exists (in any order)
    let conversation = await Conversation.findOne({
      participants: {
        $all: [currentUserId, participantId],
        $size: 2,
      },
    }).populate('participants', '_id username email');

    // If not exists, create new
    if (!conversation) {
      conversation = await Conversation.create({
        participants: [currentUserId, participantId],
      });

      // Populate participants
      await conversation.populate('participants', '_id username email');
    }

    res.status(201).json({
      success: true,
      message: 'Conversation created or retrieved successfully',
      conversation,
    });
  } catch (error) {
    console.error('Create/Get conversation error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to create/get conversation',
    });
  }
};

// @desc    Get all conversations for current user
// @route   GET /api/conversations
// @access  Private
exports.getUserConversations = async (req, res) => {
  try {
    const currentUserId = req.user.id;

    const conversations = await Conversation.find({
      participants: currentUserId,
    })
      .populate('participants', '_id username email')
      .populate({
        path: 'lastMessage',
        select: 'content senderId createdAt status',
        populate: {
          path: 'senderId',
          select: '_id username',
        },
      })
      .sort({ lastMessageAt: -1 });

    res.status(200).json({
      success: true,
      count: conversations.length,
      conversations,
    });
  } catch (error) {
    console.error('Get user conversations error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch conversations',
    });
  }
};

// @desc    Get messages from a conversation with pagination
// @route   GET /api/conversations/:id/messages
// @access  Private
exports.getConversationMessages = async (req, res) => {
  try {
    const { id } = req.params;
    const currentUserId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // Check if user is participant in this conversation
    const conversation = await Conversation.findById(id);

    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found',
      });
    }

    const isParticipant = conversation.participants.some(
      (participant) => participant.toString() === currentUserId
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You are not a participant in this conversation',
      });
    }

    // Get total count for pagination
    const totalMessages = await Message.countDocuments({
      conversationId: id,
    });

    // Get messages with pagination
    const messages = await Message.find({ conversationId: id })
      .populate('senderId', '_id username email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Reverse to get chronological order
    messages.reverse();

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
    console.error('Get conversation messages error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch messages',
    });
  }
};

// @desc    Get single conversation
// @route   GET /api/conversations/:id
// @access  Private
exports.getConversation = async (req, res) => {
  try {
    const { id } = req.params;
    const currentUserId = req.user.id;

    const conversation = await Conversation.findById(id).populate(
      'participants',
      '_id username email'
    );

    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found',
      });
    }

    // Check if user is participant
    const isParticipant = conversation.participants.some(
      (participant) => participant._id.toString() === currentUserId
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You are not a participant in this conversation',
      });
    }

    res.status(200).json({
      success: true,
      conversation,
    });
  } catch (error) {
    console.error('Get conversation error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch conversation',
    });
  }
};

// @desc    Delete conversation
// @route   DELETE /api/conversations/:id
// @access  Private
exports.deleteConversation = async (req, res) => {
  try {
    const { id } = req.params;
    const currentUserId = req.user.id;

    const conversation = await Conversation.findById(id);

    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: 'Conversation not found',
      });
    }

    // Check if user is participant
    const isParticipant = conversation.participants.some(
      (participant) => participant.toString() === currentUserId
    );

    if (!isParticipant) {
      return res.status(403).json({
        success: false,
        message: 'You are not a participant in this conversation',
      });
    }

    // Delete conversation and its messages
    await Conversation.findByIdAndDelete(id);
    await Message.deleteMany({ conversationId: id });

    res.status(200).json({
      success: true,
      message: 'Conversation deleted successfully',
    });
  } catch (error) {
    console.error('Delete conversation error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to delete conversation',
    });
  }
};
