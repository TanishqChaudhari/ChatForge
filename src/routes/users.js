const express = require('express');
const { getAllUsers, searchUsers } = require('../controllers/userController');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// All user routes are protected
router.use(authMiddleware);

// Get all users
router.get('/', getAllUsers);

// Search users
router.get('/search', searchUsers);

module.exports = router;
