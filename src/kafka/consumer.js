/**
 * Kafka Consumer
 * Consumes message events from 'messages' topic for logging/processing
 */

const { Kafka } = require('kafkajs');

const kafka = new Kafka({
  clientId: 'chatforge-consumer',
  brokers: (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
});

const consumer = kafka.consumer({
  groupId: 'chatforge-group',
  sessionTimeout: 30000,
  heartbeatInterval: 3000,
});

let isConnected = false;

async function connectConsumer() {
  try {
    if (!isConnected) {
      await consumer.connect();
      isConnected = true;
      console.log('✓ Kafka consumer connected');
    }
  } catch (err) {
    console.error('✗ Kafka consumer error:', err.message);
    throw err;
  }
}

async function subscribeToMessages() {
  try {
    await connectConsumer();

    await consumer.subscribe({
      topic: 'messages',
      fromBeginning: false, // Only new messages, not historical
    });

    await consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        try {
          const event = JSON.parse(message.value.toString());

          console.log(`[Kafka Consumer] Message event received:`, {
            topic,
            partition,
            messageId: event.messageId,
            conversationId: event.conversationId,
            senderId: event.senderId,
            content: event.content,
            status: event.status,
            timestamp: event.timestamp,
          });

          // Here you could:
          // - Log to file/database
          // - Update analytics
          // - Trigger notifications
          // - Send to other services
        } catch (err) {
          console.error('✗ Error processing message:', err.message);
        }
      },
    });
  } catch (err) {
    console.error('✗ Failed to subscribe to messages:', err.message);
    throw err;
  }
}

async function disconnectConsumer() {
  if (isConnected) {
    await consumer.disconnect();
    isConnected = false;
    console.log('✓ Kafka consumer disconnected');
  }
}

module.exports = {
  subscribeToMessages,
  disconnectConsumer,
  connectConsumer,
};
