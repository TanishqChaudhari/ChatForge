#!/bin/bash

# ============================================================================
# ChatForge Phase 4 Services - Stop Script
# ============================================================================
# Safely stops Redis, Kafka broker, and Zookeeper services
# ============================================================================

echo "🛑 Stopping ChatForge Services..."
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Stop Redis
echo "Stopping Redis..."
if redis-cli ping &> /dev/null; then
  redis-cli shutdown NOSAVE
  sleep 1
  if ! redis-cli ping &> /dev/null; then
    echo -e "${GREEN}✓${NC} Redis stopped"
  else
    echo -e "${YELLOW}⚠${NC} Redis still responding, may take a moment to shut down"
  fi
else
  echo -e "${YELLOW}⚠${NC} Redis not running"
fi

echo ""

# Stop Kafka broker
echo "Stopping Kafka broker..."
KAFKA_HOME=$(brew --prefix kafka 2>/dev/null)
if [ -n "$KAFKA_HOME" ] && command -v kafka-server-stop.sh &> /dev/null; then
  $KAFKA_HOME/bin/kafka-server-stop.sh
  sleep 2
  echo -e "${GREEN}✓${NC} Kafka broker stopped"
else
  echo -e "${YELLOW}⚠${NC} Kafka not found or not running"
fi

echo ""

# Stop Zookeeper
echo "Stopping Zookeeper..."
if [ -n "$KAFKA_HOME" ] && command -v zookeeper-server-stop.sh &> /dev/null; then
  $KAFKA_HOME/bin/zookeeper-server-stop.sh
  sleep 1
  echo -e "${GREEN}✓${NC} Zookeeper stopped"
else
  echo -e "${YELLOW}⚠${NC} Zookeeper not found or not running"
fi

echo ""
echo -e "${GREEN}✓${NC} All services stopped"
echo ""
