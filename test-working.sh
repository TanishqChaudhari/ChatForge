#!/bin/bash

# ChatForge Phase 4 - Working Test Suite
# Fixed to properly extract conversation ID from nested response

set -e

BASE_URL="http://localhost:8000"
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

passed=0
failed=0

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}ChatForge Phase 4 - Full Feature Test${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Generate unique IDs for this run
TS=$(date +%s%N)
ALICE_USER="alice_$TS"
ALICE_EMAIL="alice_$TS@test.com"
BOB_USER="bob_$TS"
BOB_EMAIL="bob_$TS@test.com"

log_pass() { echo -e "${GREEN}✓ $1${NC}"; ((passed++)); }
log_fail() { echo -e "${RED}✗ $1${NC}"; ((failed++)); }

# TEST 1: Register Alice
echo "TEST 1: Register Alice"
ALICE=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "username": "$ALICE_USER",
  "email": "$ALICE_EMAIL",
  "password": "test123",
  "passwordConfirm": "test123"
}
EOF
)
ALICE_ID=$(echo "$ALICE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$ALICE_ID" ]; then
  log_pass "Alice registered (ID: ${ALICE_ID:0:8}...)"
else
  log_fail "Alice registration failed"
  echo "Response: $ALICE" | head -1
  exit 1
fi

# TEST 2: Register Bob
echo "TEST 2: Register Bob"
BOB=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "username": "$BOB_USER",
  "email": "$BOB_EMAIL",
  "password": "test123",
  "passwordConfirm": "test123"
}
EOF
)
BOB_ID=$(echo "$BOB" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$BOB_ID" ]; then
  log_pass "Bob registered (ID: ${BOB_ID:0:8}...)"
else
  log_fail "Bob registration failed"
  exit 1
fi

# TEST 3: Login Alice
echo "TEST 3: Login Alice"
LOGIN=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "email": "$ALICE_EMAIL",
  "password": "test123"
}
EOF
)
TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$TOKEN" ]; then
  log_pass "Alice login successful"
else
  log_fail "Alice login failed"
  exit 1
fi

# TEST 4: Create Conversation
echo "TEST 4: Create conversation"
CONV=$(curl -s -X POST $BASE_URL/api/conversations \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "participantId": "$BOB_ID"
}
EOF
)

# Extract conversation ID from nested object
CONV_ID=$(echo "$CONV" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$CONV_ID" ]; then
  log_pass "Conversation created (ID: ${CONV_ID:0:8}...)"
else
  log_fail "Conversation creation failed"
  echo "Response: $CONV" | head -1
  exit 1
fi

# TEST 5: Send Message
echo "TEST 5: Send message via REST API"
MESSAGE=$(curl -s -X POST $BASE_URL/api/messages \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "conversationId": "$CONV_ID",
  "content": "Hello Bob, this is a test message!",
  "receiverId": "$BOB_ID"
}
EOF
)

if echo "$MESSAGE" | grep -q '"status":"sent"'; then
  log_pass "Message sent successfully"
else
  log_fail "Message send failed"
  echo "Response: $MESSAGE" | head -1
fi

# TEST 6: Get Online Users (Redis)
echo "TEST 6: Get online users from Redis"
ONLINE=$(curl -s -X GET $BASE_URL/api/users/online \
  -H "Authorization: Bearer $TOKEN")

if echo "$ONLINE" | grep -q "onlineUsers"; then
  COUNT=$(echo "$ONLINE" | grep -o '"count":[0-9]*' | cut -d':' -f2)
  log_pass "Online users endpoint working (count: $COUNT)"
else
  log_fail "Online users endpoint failed"
fi

# TEST 7: Check specific user status
echo "TEST 7: Check user online status"
STATUS=$(curl -s -X GET $BASE_URL/api/users/$BOB_ID/online-status \
  -H "Authorization: Bearer $TOKEN")

if echo "$STATUS" | grep -q "isOnline"; then
  log_pass "User status endpoint working"
else
  log_fail "User status endpoint failed"
fi

# TEST 8: Retrieve message
echo "TEST 8: Retrieve sent messages"
MESSAGES=$(curl -s -X GET "$BASE_URL/api/messages?conversationId=$CONV_ID" \
  -H "Authorization: Bearer $TOKEN")

if echo "$MESSAGES" | grep -q "$CONV_ID"; then
  log_pass "Message retrieval working"
else
  log_fail "Message retrieval failed"
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo -e "${BLUE}Test Summary:${NC}"
echo -e "${GREEN}Passed: $passed${NC}"
echo -e "${RED}Failed: $failed${NC}"

if [ $failed -eq 0 ]; then
  echo -e "${GREEN}✓✓✓ ALL TESTS PASSED ✓✓✓${NC}"
  exit 0
else
  echo -e "${RED}✗✗✗ SOME TESTS FAILED ✗✗✗${NC}"
  exit 1
fi
