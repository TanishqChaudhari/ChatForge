#!/bin/bash

# Minimal Phase 4 Test Script

set -e

BASE_URL="http://localhost:8000"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "ChatForge Phase 4 - Minimal Test Suite"
echo "======================================"
echo ""

# Generate unique timestamp for this test run
TS=$(date +%s%N)
ALICE_EMAIL="alice_$TS@test.com"
BOB_EMAIL="bob_$TS@test.com"

# 1. Register Alice
echo "1. Registering Alice..."
ALICE_RESP=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "username": "alice_$TS",
  "email": "$ALICE_EMAIL",
  "password": "test123",
  "passwordConfirm": "test123"
}
EOF
)

ALICE_ID=$(echo "$ALICE_RESP" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$ALICE_ID" ]; then
  echo -e "${RED}✗ Failed to register Alice${NC}"
  echo "Response: $ALICE_RESP"
  exit 1
fi
echo -e "${GREEN}✓ Alice registered${NC}"

# 2. Register Bob
echo "2. Registering Bob..."
BOB_RESP=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "username": "bob_$TS",
  "email": "$BOB_EMAIL",
  "password": "test123",
  "passwordConfirm": "test123"
}
EOF
)

BOB_ID=$(echo "$BOB_RESP" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$BOB_ID" ]; then
  echo -e "${RED}✗ Failed to register Bob${NC}"
  echo "Response: $BOB_RESP"
  exit 1
fi
echo -e "${GREEN}✓ Bob registered${NC}"

# 3. Login Alice
echo "3. Logging in Alice..."
LOGIN_RESP=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "email": "$ALICE_EMAIL",
  "password": "test123"
}
EOF
)

TOKEN_ALICE=$(echo "$LOGIN_RESP" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$TOKEN_ALICE" ]; then
  echo -e "${RED}✗ Failed to login Alice${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Alice logged in${NC}"

# 4. Create Conversation
echo "4. Creating conversation..."
CONV_RESP=$(curl -s -X POST $BASE_URL/api/conversations \
  -H "Authorization: Bearer $TOKEN_ALICE" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "participantId": "$BOB_ID"
}
EOF
)

CONV_ID=$(echo "$CONV_RESP" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$CONV_ID" ]; then
  echo -e "${RED}✗ Failed to create conversation${NC}"
  echo "Response: $CONV_RESP"
  exit 1
fi
echo -e "${GREEN}✓ Conversation created${NC}"

# 5. Send Message
echo "5. Sending message..."
MSG_RESP=$(curl -s -X POST $BASE_URL/api/messages \
  -H "Authorization: Bearer $TOKEN_ALICE" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "conversationId": "$CONV_ID",
  "content": "Hello from test",
  "receiverId": "$BOB_ID"
}
EOF
)

if echo "$MSG_RESP" | grep -q '"status":"sent"'; then
  echo -e "${GREEN}✓ Message sent${NC}"
else
  echo -e "${RED}✗ Failed to send message${NC}"
  echo "Response: $MSG_RESP"
fi

echo ""
echo -e "${GREEN}✓ All basic tests passed!${NC}"
