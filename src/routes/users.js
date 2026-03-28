const express = require('express');
const { getAllUsers, searchUsers } = require('../controllers/userController');
const authMiddleware = require('../middleware/auth');
const redis = require('../redis/client');
const User = require('../models/User');

const router = express.Router();

// All user routes are protected
router.use(authMiddleware);

// Get all users
router.get('/', getAllUsers);

// Search users
router.get('/search', searchUsers);

/**
 * GET /api/users/online
 * Get list of all currently online users
 */
router.get('/online', async (req, res) => {
  try {
    // Get all keys matching user:*:online pattern from Redis
    const keys = await redis.keys('user:*:online');

    if (keys.length === 0) {
      return res.json({
        success: true,
        users: [],
        count: 0,
      });
    }

    // Extract user IDs from keys
    const userIds = keys.map((key) => key.split(':')[1]);

    // Fetch user details from database
    const users = await User.find({ _id: { $in: userIds } }).select(
      '_id username email lastSeen'
    );

    res.json({
      success: true,
      users: users.map((user) => ({
        id: user._id,
        username: user.username,
        email: user.email,
        lastSeen: user.lastSeen || null,
      })),
      count: users.length,
    });
  } catch (err) {
    console.error('Get online users error:', err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

/**
 * GET /api/users/:userId/online-status
 * Check if specific user is online
 */
router.get('/:userId/online-status', async (req, res) => {
  try {
    const { userId } = req.params;

    // Check if user key exists in Redis
    const exists = await redis.exists(`user:${userId}:online`);

    res.json({
      success: true,
      userId,
      isOnline: exists === 1,
    });
  } catch (err) {
    console.error('Check online status error:', err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

module.exports = router;
