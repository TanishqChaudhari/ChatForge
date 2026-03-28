#!/bin/bash

# ============================================================================
# Monitor Kafka Message Events - Real-time Consumer
# ============================================================================
# Displays all message events being published to Kafka topic 'messages'
# Run this in a separate terminal while the server is running
# ============================================================================

echo "📊 Kafka Message Event Monitor"
echo "=============================="
echo ""
echo "Connecting to Kafka topic 'messages'..."
echo "Press Ctrl+C to exit"
echo ""

node src/kafka/consumer.js
