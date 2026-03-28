/**
 * Kafka Producer
 * Produces message events to 'messages' topic for event streaming
 */

const { Kafka } = require('kafkajs');

const kafka = new Kafka({
  clientId: 'chatforge-producer',
  brokers: (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
});

const producer = kafka.producer({
  transactionTimeout: 30000,
});

let isConnected = false;

async function connectProducer() {
  try {
    if (!isConnected) {
      await producer.connect();
      isConnected = true;
      console.log('✓ Kafka producer connected');
    }
  } catch (err) {
    console.error('✗ Kafka producer error:', err.message);
    throw err;
  }
}

async function produceMessageEvent(message) {
  try {
    await connectProducer();

    const event = {
      messageId: message._id.toString(),
      conversationId: message.conversationId.toString(),
      senderId: message.senderId.toString(),
      content: message.content,
      status: message.status,
      timestamp: new Date().toISOString(),
    };

    await producer.send({
      topic: 'messages',
      messages: [
        {
          key: message.conversationId.toString(),
          value: JSON.stringify(event),
          timestamp: Date.now().toString(),
        },
      ],
    });

    console.log(`✓ Message event produced: ${message._id}`);
  } catch (err) {
    console.error('✗ Failed to produce message event:', err.message);
    throw err;
  }
}

async function disconnectProducer() {
  if (isConnected) {
    await producer.disconnect();
    isConnected = false;
    console.log('✓ Kafka producer disconnected');
  }
}

module.exports = {
  produceMessageEvent,
  disconnectProducer,
  connectProducer,
};
