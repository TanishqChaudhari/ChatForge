#!/bin/bash

# ============================================================================
# ChatForge Phase 4 Infrastructure Setup Script
# ============================================================================
# This script sets up Redis and Kafka services for presence tracking and 
# event streaming. Run this ONCE before starting the application.
# ============================================================================

set -e

echo "📦 ChatForge Phase 4 Infrastructure Setup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
check_command() {
  if command -v $1 &> /dev/null; then
    echo -e "${GREEN}✓${NC} $1 found"
    return 0
  else
    echo -e "${RED}✗${NC} $1 not found"
    return 1
  fi
}

wait_for_service() {
  local port=$1
  local name=$2
  local max_attempts=30
  local attempt=0
  
  echo -e "${BLUE}  Waiting for $name on port $port...${NC}"
  
  while [ $attempt -lt $max_attempts ]; do
    if nc -z localhost $port &> /dev/null; then
      echo -e "  ${GREEN}✓${NC} $name is running"
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 1
  done
  
  echo -e "  ${RED}✗${NC} $name failed to start (timeout)"
  return 1
}

# ============================================================================
# 1. Check Prerequisites
# ============================================================================
echo "1️⃣  Checking Prerequisites..."
echo ""

if ! check_command "brew"; then
  echo -e "${RED}✗ Homebrew not found. Please install from https://brew.sh${NC}"
  exit 1
fi

if ! check_command "nc"; then
  echo -e "${YELLOW}⚠ netcat not found, will skip service port checks${NC}"
fi

echo ""

# ============================================================================
# 2. Install Redis (if needed)
# ============================================================================
echo "2️⃣  Setting up Redis..."
echo ""

if ! check_command "redis-server"; then
  echo "  Installing Redis via Homebrew..."
  brew install redis
  echo ""
fi

echo ""

# ============================================================================
# 3. Install Kafka (if needed)
# ============================================================================
echo "3️⃣  Setting up Kafka..."
echo ""

if ! check_command "kafka-server-start"; then
  echo "  Installing Kafka via Homebrew..."
  brew install kafka
  echo ""
fi

# Verify Kafka installation
KAFKA_HOME=$(brew --prefix kafka)
if [ ! -d "$KAFKA_HOME" ]; then
  echo -e "${RED}✗ Kafka installation failed${NC}"
  exit 1
fi

echo -e "${GREEN}✓${NC} Kafka found at: $KAFKA_HOME"
echo ""

# ============================================================================
# 4. Start Redis
# ============================================================================
echo "4️⃣  Starting Redis..."
echo ""

# Check if Redis is already running
if redis-cli ping &> /dev/null; then
  echo -e "${GREEN}✓${NC} Redis already running"
else
  echo "  Starting Redis server..."
  redis-server --daemonize yes --loglevel warning
  sleep 2
  
  if redis-cli ping &> /dev/null; then
    echo -e "${GREEN}✓${NC} Redis started successfully"
  else
    echo -e "${RED}✗${NC} Failed to start Redis"
    exit 1
  fi
fi

echo ""

# ============================================================================
# 5. Start Kafka Zookeeper
# ============================================================================
echo "5️⃣  Starting Kafka Zookeeper..."
echo ""

# Check if Zookeeper is already running
if nc -z localhost 2181 &> /dev/null; then
  echo -e "${GREEN}✓${NC} Zookeeper already running"
else
  echo "  Starting Zookeeper..."
  
  # Start Zookeeper in background
  $KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties
  
  # Wait for Zookeeper to start
  sleep 3
  if nc -z localhost 2181 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Zookeeper started (port 2181)"
  else
    echo -e "${YELLOW}⚠${NC} Zookeeper may still be starting..."
  fi
fi

echo ""

# ============================================================================
# 6. Start Kafka Broker
# ============================================================================
echo "6️⃣  Starting Kafka Broker..."
echo ""

# Check if Kafka broker is already running
if nc -z localhost 9092 &> /dev/null; then
  echo -e "${GREEN}✓${NC} Kafka broker already running"
else
  echo "  Starting Kafka broker..."
  
  # Start Kafka broker in background
  $KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties
  
  # Wait for Kafka to start
  sleep 5
  if nc -z localhost 9092 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Kafka broker started (port 9092)"
  else
    echo -e "${YELLOW}⚠${NC} Kafka broker may still be starting..."
  fi
fi

echo ""

# ============================================================================
# 7. Verify Services
# ============================================================================
echo "7️⃣  Verifying Services..."
echo ""

# Redis check
if redis-cli ping &> /dev/null; then
  echo -e "${GREEN}✓${NC} Redis: CONNECTED (port 6379)"
else
  echo -e "${RED}✗${NC} Redis: NOT RESPONDING"
fi

# Zookeeper check
if nc -z localhost 2181 &> /dev/null; then
  echo -e "${GREEN}✓${NC} Zookeeper: RUNNING (port 2181)"
else
  echo -e "${YELLOW}⚠${NC} Zookeeper: NOT RESPONDING (may still be starting)"
fi

# Kafka check
if nc -z localhost 9092 &> /dev/null; then
  echo -e "${GREEN}✓${NC} Kafka: RUNNING (port 9092)"
else
  echo -e "${YELLOW}⚠${NC} Kafka: NOT RESPONDING (may still be starting)"
fi

echo ""

# ============================================================================
# 8. Create Kafka Topic
# ============================================================================
echo "8️⃣  Setting up Kafka Topic..."
echo ""

# Wait a bit more for Kafka to fully initialize
sleep 2

# Create 'messages' topic if it doesn't exist
if $KAFKA_HOME/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list 2>/dev/null | grep -q "^messages\$"; then
  echo -e "${GREEN}✓${NC} Topic 'messages' already exists"
else
  echo "  Creating 'messages' topic..."
  $KAFKA_HOME/bin/kafka-topics.sh \
    --bootstrap-server localhost:9092 \
    --create \
    --topic messages \
    --partitions 3 \
    --replication-factor 1 \
    --if-not-exists
  echo -e "${GREEN}✓${NC} Topic 'messages' created"
fi

echo ""

# ============================================================================
# 9. Summary
# ============================================================================
echo "✨ Setup Complete!"
echo "=========================================="
echo ""
echo "Services are now running:"
echo "  • Redis: localhost:6379"
echo "  • Zookeeper: localhost:2181"
echo "  • Kafka: localhost:9092"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. In a new terminal, start the ChatForge server:"
echo "   npm start"
echo ""
echo "2. In another terminal, run the Phase 4 test suite:"
echo "   bash test-phase4.sh"
echo ""
echo "3. (Optional) Monitor Kafka events in real-time:"
echo "   node src/kafka/consumer.js"
echo ""
echo "To stop services later, run:"
echo "   redis-cli shutdown"
echo "   kafka-server-stop"
echo ""
