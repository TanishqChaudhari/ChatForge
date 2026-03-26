# ChatForge - Real-time Chat Application

A modern real-time chat application built with Node.js, Express, MongoDB, Socket.io, and JWT authentication.

## Features

- 🔐 JWT-based user authentication
- 🔑 Bcrypt password hashing
- 📦 MongoDB with Mongoose ODM
- ⚡ Real-time communication with Socket.io
- 📨 Redis caching (configured)
- 🎯 Apache Kafka for event streaming (configured)
- 🛡️ Protected routes with authentication middleware
- ✅ CORS enabled for cross-origin requests

## Project Structure

```
ChatForge/
├── src/
│   ├── config/
│   │   └── database.js          # MongoDB connection configuration
│   ├── controllers/
│   │   └── authController.js    # Authentication logic
│   ├── middleware/
│   │   └── auth.js              # JWT authentication middleware
│   ├── models/
│   │   └── User.js              # User schema with bcrypt hashing
│   ├── routes/
│   │   └── auth.js              # Authentication routes
│   └── index.js                 # Main entry point
├── package.json                 # Dependencies
├── .env.example                 # Environment variables template
└── .gitignore                   # Git ignore rules
```

## Prerequisites

- Node.js (v14 or higher)
- MongoDB (running locally or connected via URI)
- npm or yarn

## Installation

### 1. Install Dependencies

```bash
npm install
```

### 2. Setup Environment Variables

Copy `.env.example` to `.env` and update the values:

```bash
cp .env.example .env
```

**Important environment variables:**
- `MONGODB_URI`: MongoDB connection string
- `JWT_SECRET`: Secret key for JWT signing (change this!)
- `PORT`: Server port (default: 5000)
- `CORS_ORIGIN`: Frontend origin for CORS

### 3. Start the Server

**Development mode (with auto-reload):**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

The server will start on `http://localhost:5000`

## API Endpoints

### Authentication Routes

#### Register User
```
POST /api/auth/register
Content-Type: application/json

{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "securePassword123",
  "passwordConfirm": "securePassword123"
}

Response:
{
  "success": true,
  "message": "User registered successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "60d5ec49f1b2c72d8c8e8e1a",
    "username": "johndoe",
    "email": "john@example.com"
  }
}
```

#### Login User
```
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securePassword123"
}

Response:
{
  "success": true,
  "message": "Logged in successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "60d5ec49f1b2c72d8c8e8e1a",
    "username": "johndoe",
    "email": "john@example.com"
  }
}
```

#### Get Current User (Protected)
```
GET /api/auth/me
Authorization: Bearer <your_jwt_token>

Response:
{
  "success": true,
  "user": {
    "_id": "60d5ec49f1b2c72d8c8e8e1a",
    "username": "johndoe",
    "email": "john@example.com",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "updatedAt": "2024-01-15T10:30:00.000Z"
  }
}
```

## Authentication Usage

### Using Protected Routes

All protected routes require the JWT token in the Authorization header:

```
Authorization: Bearer <token>
```

Example with cURL:
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  http://localhost:5000/api/auth/me
```

Example with JavaScript fetch:
```javascript
const token = localStorage.getItem('token');

fetch('http://localhost:5000/api/auth/me', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
})
.then(res => res.json())
.then(data => console.log(data));
```

## Socket.io Events

### Available Socket Events

- `join_room`: Join a chat room
- `leave_room`: Leave a chat room
- `disconnect`: User disconnect

Example Socket.io client usage:
```javascript
const io = require('socket.io-client');
const socket = io('http://localhost:5000');

socket.on('connect', () => {
  console.log('Connected to server');
  socket.emit('join_room', 'general');
});

socket.on('disconnect', () => {
  console.log('Disconnected from server');
});
```

## Security Features

- ✅ Passwords are hashed with bcrypt (10 rounds)
- ✅ JWT tokens with expiration
- ✅ Protected routes with authentication middleware
- ✅ Input validation on registration and login
- ✅ CORS protection
- ✅ Environment variable isolation

## Development

### Available Scripts

```bash
npm start    # Start production server
npm run dev  # Start development server with nodemon
npm test     # Run tests (to be configured)
```

## Next Steps

1. Add more API routes for chat functionality
2. Implement Redis caching for user sessions
3. Configure Kafka for message event streaming
4. Add WebSocket authentication
5. Implement room-based messaging
6. Add user presence tracking
7. Implement message history persistence

## Troubleshooting

### MongoDB Connection Error
- Ensure MongoDB is running locally or check your `MONGODB_URI` in `.env`
- Default local connection: `mongodb://localhost:27017/chatforge`

### JWT Token Errors
- Verify `JWT_SECRET` is set in `.env`
- Check token format: `Bearer <token>`
- Ensure token hasn't expired

### CORS Errors
- Update `CORS_ORIGIN` in `.env` to match your frontend URL
- Default is `http://localhost:3000`

## License

ISC

## Author

ChatForge Team
