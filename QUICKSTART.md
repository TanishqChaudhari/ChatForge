# ChatForge Phase 4 - Quick Start Guide

## Overview

Phase 4 adds Redis-based presence tracking and Kafka-based event streaming to ChatForge. This guide will get you running in 5 minutes.

## Prerequisites

- Node.js 14+ (must be installed)
- macOS with Homebrew (or Linux with apt/brew equivalent)
- Git

## One-Time Setup

### Step 1: Install & Start Services

```bash
# Make setup script executable
chmod +x setup-services.sh

# Run setup (installs Redis, Kafka, starts both services)
./setup-services.sh
```

This script will:
- ✅ Install Redis via Homebrew (if not already installed)
- ✅ Install Kafka via Homebrew (if not already installed)
- ✅ Start Redis on port 6379
- ✅ Start Zookeeper on port 2181
- ✅ Start Kafka broker on port 9092
- ✅ Create the 'messages' Kafka topic

**Expected output:**
```
✨ Setup Complete!
Services are now running:
  • Redis: localhost:6379
  • Zookeeper: localhost:2181
  • Kafka: localhost:9092
```

### Step 2: Install Node Dependencies

```bash
npm install
```

This installs all required packages including `ioredis` and `kafkajs`.

## Running the Application

### Terminal 1: Start MongoDB (if using locally)

If you have MongoDB running locally:
```bash
mongod
```

Or ensure your MongoDB Atlas connection string is set in `.env`.

### Terminal 2: Start ChatForge Server

```bash
npm start
```

Expected output:
```
✓ MongoDB connected
✓ Redis connected - User presence tracking enabled
✓ Kafka Producer ready
Server running on http://localhost:3000
```

### Terminal 3: (Optional) Monitor Kafka Events

To see all message events in real-time:

```bash
chmod +x monitor-kafka.sh
./monitor-kafka.sh
```

This shows every message event published to Kafka as it happens (useful for debugging/monitoring).

## Testing Phase 4

In a **new terminal**, run the complete test suite:

```bash
bash test-phase4.sh
```

This tests:
- ✅ User registration and authentication
- ✅ Redis presence tracking (GET /api/users/online)
- ✅ Individual user online status (GET /api/users/:userId/online-status)
- ✅ Message sending with Kafka event production
- ✅ Message persistence to MongoDB

**Expected output:**
```
✅ All 8 Phase 4 tests passed!
```

## Key Files & Their Roles

| File | Purpose |
|------|---------|
| `src/redis/client.js` | Redis connection (presence cache) |
| `src/kafka/producer.js` | Produces message events to Kafka |
| `src/kafka/consumer.js` | Consumes and logs message events |
| `src/socket/index.js` | Socket.io with Redis + Kafka integration |
| `src/controllers/messageController.js` | REST API messages with Kafka |
| `src/routes/users.js` | New endpoints: `/api/users/online`, `/api/users/:userId/online-status` |
| `setup-services.sh` | Installs & starts Redis + Kafka |
| `stop-services.sh` | Stops all services safely |
| `monitor-kafka.sh` | Real-time Kafka event monitor |

## New API Endpoints

### Get All Online Users
```bash
GET /api/users/online
Authorization: Bearer <JWT_TOKEN>

Response:
{
  "onlineUsers": [
    {
      "id": "user_id",
      "username": "john_doe",
      "email": "john@example.com",
      "lastSeen": "2025-01-15T10:30:00Z"
    }
  ]
}
```

### Get User Online Status
```bash
GET /api/users/:userId/online-status
Authorization: Bearer <JWT_TOKEN>

Response:
{
  "userId": "user_id",
  "isOnline": true
}
```

## How It Works

### Presence Tracking (Redis)

1. User connects via Socket.io → Redis stores `user:${userId}:online` with 5-minute expiry
2. User disconnects → Redis key is deleted immediately
3. `GET /api/users/online` → Returns all users with keys in Redis

### Message Events (Kafka)

1. User sends message (REST or Socket.io)
2. Message saved to MongoDB
3. Message event published to Kafka 'messages' topic
4. Optional consumer processes events (analytics, notifications, etc.)

## Stopping Services

When done, stop all services:

```bash
chmod +x stop-services.sh
./stop-services.sh
```

Or manually:
```bash
redis-cli shutdown      # Stop Redis
kafka-server-stop       # Stop Kafka broker
zookeeper-server-stop   # Stop Zookeeper
```

## Troubleshooting

### Redis not connecting?
```bash
# Check if Redis is running
redis-cli ping
# Should respond: PONG

# If not running, start it
redis-server --daemonize yes
```

### Kafka not working?
```bash
# Check if broker is listening
nc -z localhost 9092
# Should succeed silently

# If not, restart Kafka
kafka-server-start /usr/local/etc/kafka/server.properties &
```

### Tests failing?
1. Ensure all services are running: `redis-cli ping`, `nc -z localhost 9092`
2. Check server logs for errors
3. Verify `.env` has correct MongoDB connection

### Port already in use?
```bash
# Find process using port 6379 (Redis)
lsof -i :6379

# Find process using port 9092 (Kafka)
lsof -i :9092

# Kill if needed
kill -9 <PID>
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client (Web/Socket)                      │
└────────────┬────────────────────────────────────┬────────────────┘
             │                                    │
             ▼                                    ▼
      ┌─────────────┐                    ┌──────────────┐
      │ Socket.io   │                    │  REST API    │
      │  Handler    │                    │  Endpoint    │
      └──────┬──────┘                    └──────┬───────┘
             │                                  │
             ├──────────────┬───────────────────┤
             │              │                   │
             ▼              ▼                   ▼
        ┌────────┐    ┌─────────┐      ┌──────────────┐
        │ Redis  │    │MongoDB  │      │  Kafka       │
        │(Online)│    │(Messages)│     │(Event Stream)│
        └────────┘    └─────────┘      └──────────────┘
             ▲
             │
        GET /api/users/online
        GET /api/users/:userId/online-status
```

## Performance Notes

- **Redis TTL**: 5 minutes (auto-cleanup of stale presence)
- **Kafka Partitions**: 3 (for distributed event processing)
- **Consumer Offset**: fromBeginning=false (only new events)

## Next Steps

1. ✅ Run `./setup-services.sh` to start infrastructure
2. ✅ Run `npm start` to start the server
3. ✅ Run `bash test-phase4.sh` to verify everything works
4. ✅ Explore new endpoints in Postman/curl
5. ✅ Monitor events with `./monitor-kafka.sh`

## Support

For detailed technical documentation, see:
- [Phase 4 Context Guide](./READ/Context/phase4_context.txt)
- [Phase 4 Learning Guide](./READ/Understand/phase4_understand.txt)

---

**Phase 4 Status:** ✅ Complete & Ready
