const jwt = require('jsonwebtoken');
const Message = require('../models/Message');
const Conversation = require('../models/Conversation');
const User = require('../models/User');
const redis = require('../redis/client');
const { produceMessageEvent } = require('../kafka/producer');

// Store active users: {userId: socketId}
const activeUsers = {};

/**
 * Initialize Socket.io with JWT authentication and real-time messaging
 */
module.exports = (io) => {
  // ❶ Socket.io Middleware: Verify JWT token on connection
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth.token;

      if (!token) {
        return next(new Error('Authentication required'));
      }

      // Verify JWT
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_super_secret_jwt_key_change_this_in_production');
      socket.userId = decoded.id; // Attach userId to socket
      socket.user = decoded;
      next();
    } catch (error) {
      console.error('Socket authentication error:', error.message);
      next(new Error('Invalid token'));
    }
  });

  // ❷ Connection Handler
  io.on('connection', async (socket) => {
    const userId = socket.userId;
    activeUsers[userId] = socket.id;

    console.log(`✓ User connected: ${userId} (socket: ${socket.id})`);
    
    // Set user online in Redis with 5-minute expiration
    try {
      await redis.setex(`user:${userId}:online`, 300, 'true');
      console.log(`✓ Redis: User ${userId} set online`);
    } catch (err) {
      console.error(`✗ Redis error setting online status:`, err.message);
    }
    
    // User joins their own room for direct messages
    socket.join(userId);

    // Broadcast user online status
    socket.broadcast.emit('user_online', { userId, timestamp: new Date() });

    // ❸ Send Message Event
    socket.on('send_message', async (data) => {
      try {
        const { conversationId, content } = data;
        const senderId = userId;

        // Validate input
        if (!conversationId || !content) {
          socket.emit('error', { message: 'Missing required fields' });
          return;
        }

        // Check if user is participant in this conversation
        const conversation = await Conversation.findById(conversationId);
        if (!conversation) {
          socket.emit('error', { message: 'Conversation not found' });
          return;
        }

        const isParticipant = conversation.participants.some(
          (p) => p.toString() === senderId
        );

        if (!isParticipant) {
          socket.emit('error', { message: 'You are not a participant in this conversation' });
          return;
        }

        // Get receiver ID (the other participant)
        const receiverId = conversation.participants.find(
          (p) => p.toString() !== senderId
        ).toString();

        // Create and save message to database
        const message = await Message.create({
          conversationId,
          senderId,
          content,
          status: 'sent',
          deliveredAt: new Date(),
        });

        // Populate sender details
        await message.populate('senderId', '_id username email');

        // Update conversation's lastMessage
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
          // Don't fail the message send, just log the error
        }

        // ✓ Response to sender
        socket.emit('message_sent', {
          messageId: message._id,
          status: 'delivered',
          timestamp: message.createdAt,
        });

        // ✓ Emit to receiver in their room
        io.to(receiverId).emit('message_received', {
          _id: message._id,
          conversationId,
          senderId: message.senderId,
          content: message.content,
          status: 'delivered',
          createdAt: message.createdAt,
          senderName: message.senderId.username,
        });

        console.log(`✓ Message sent from ${senderId} to ${receiverId}`);
      } catch (error) {
        console.error('Send message error:', error);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // ❹ Typing Indicator Start
    socket.on('typing_start', (data) => {
      try {
        const { conversationId } = data;

        // Emit typing indicator to all participants in conversation
        socket.broadcast.to(conversationId).emit('user_typing', {
          userId,
          username: socket.user.username,
          conversationId,
        });

        console.log(`✓ ${socket.user.username} is typing in ${conversationId}`);
      } catch (error) {
        console.error('Typing start error:', error);
      }
    });

    // ❺ Typing Indicator Stop
    socket.on('typing_stop', (data) => {
      try {
        const { conversationId } = data;

        // Emit stop typing to all participants in conversation
        socket.broadcast.to(conversationId).emit('user_stopped_typing', {
          userId,
          username: socket.user.username,
          conversationId,
        });

        console.log(`✓ ${socket.user.username} stopped typing in ${conversationId}`);
      } catch (error) {
        console.error('Typing stop error:', error);
      }
    });

    // ❻ Message Read Receipt
    socket.on('message_read', async (data) => {
      try {
        const { messageId, conversationId } = data;
        const readerId = userId;

        // Find and update message
        const message = await Message.findByIdAndUpdate(
          messageId,
          {
            status: 'read',
            readAt: new Date(),
          },
          { new: true }
        );

        if (!message) {
          socket.emit('error', { message: 'Message not found' });
          return;
        }

        // Get sender ID
        const senderId = message.senderId.toString();

        // Emit read receipt to sender
        io.to(senderId).emit('message_read_receipt', {
          messageId,
          conversationId,
          readBy: readerId,
          readAt: message.readAt,
        });

        console.log(`✓ Message ${messageId} marked as read by ${readerId}`);
      } catch (error) {
        console.error('Message read error:', error);
        socket.emit('error', { message: 'Failed to mark message as read' });
      }
    });

    // ❼ Join Conversation Room
    socket.on('join_conversation', (data) => {
      try {
        const { conversationId } = data;
        socket.join(conversationId);
        console.log(`✓ User ${userId} joined conversation ${conversationId}`);
      } catch (error) {
        console.error('Join conversation error:', error);
      }
    });

    // ❽ Leave Conversation Room
    socket.on('leave_conversation', (data) => {
      try {
        const { conversationId } = data;
        socket.leave(conversationId);
        console.log(`✓ User ${userId} left conversation ${conversationId}`);
      } catch (error) {
        console.error('Leave conversation error:', error);
      }
    });

    // ❾ Disconnect Handler
    socket.on('disconnect', async () => {
      delete activeUsers[userId];
      console.log(`✗ User disconnected: ${userId}`);

      // Delete user online status from Redis
      try {
        await redis.del(`user:${userId}:online`);
        console.log(`✓ Redis: User ${userId} set offline`);
      } catch (err) {
        console.error(`✗ Redis error deleting online status:`, err.message);
      }

      // Broadcast user offline status
      socket.broadcast.emit('user_offline', { userId, timestamp: new Date() });
    });
  });

  // Export activeUsers for potential API endpoints
  return { activeUsers };
};
