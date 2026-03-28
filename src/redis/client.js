/**
 * Redis Client Configuration
 * Connects to local/cloud Redis instance for presence tracking
 * Gracefully handles connection failures - optional for core functionality
 */

const Redis = require('ioredis');

let redisConnected = false;

const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: process.env.REDIS_PORT || 6379,
  retryStrategy: (times) => {
    const delay = Math.min(times * 50, 2000);
    return delay;
  },
  enableReadyCheck: false,
  enableOfflineQueue: false,
  maxRetriesPerRequest: 3,
  connectTimeout: 5000,
});

redis.on('connect', () => {
  redisConnected = true;
  console.log('✓ Redis connected - User presence tracking enabled');
});

redis.on('error', (err) => {
  redisConnected = false;
  console.warn('⚠ Redis unavailable:', err.message);
  console.warn('  (Phase 4 presence features will be limited)');
});

redis.on('reconnecting', () => {
  console.log('↻ Redis attempting reconnection...');
});

module.exports = redis;
