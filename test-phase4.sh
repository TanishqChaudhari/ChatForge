#!/bin/bash

# ChatForge Phase 4 - Complete Test Suite (All 8 Tests)
# Using jq for reliable JSON parsing

BASE_URL="http://localhost:8000"
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

passed=0
failed=0

log_step() { echo -e "${BLUE}$1${NC}"; }
log_success() { echo -e "${GREEN}✓ $1${NC}"; ((passed++)); }
log_error() { echo -e "${RED}✗ $1${NC}"; ((failed++)); }

# Clean database
log_step "Cleaning database..."
mongosh localhost:27017/chatforge --eval "
  db.users.deleteMany({});
  db.conversations.deleteMany({});
  db.messages.deleteMany({});
" 2>/dev/null || true

log_step "\n═══════════════════════════════════════════════════════════════"
log_step "ChatForge Phase 4 - All Feature Tests (8/8)"
log_step "═══════════════════════════════════════════════════════════════\n"

# Generate unique identifiers
TS=$(date +%s%N)
ALICE_USER="alice_$TS"
ALICE_EMAIL="alice_$TS@test.com"
BOB_USER="bob_$TS"
BOB_EMAIL="bob_$TS@test.com"

# ========== TEST 1: Register Alice ==========
log_step "TEST 1/8: Register Alice"
ALICE=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  --data "{\"username\":\"$ALICE_USER\",\"email\":\"$ALICE_EMAIL\",\"password\":\"pass123\",\"passwordConfirm\":\"pass123\"}")

ALICE_ID=$(echo "$ALICE" | jq -r '.user.id // empty' 2>/dev/null)
ALICE_RESP_CODE=$(echo "$ALICE" | jq -r '.success' 2>/dev/null)

if [ "$ALICE_RESP_CODE" = "true" ] && [ -n "$ALICE_ID" ]; then
  log_success "Alice registered"
else
  log_error "Alice registration failed"
  echo "Response: $ALICE"
  exit 1
fi

# ========== TEST 2: Register Bob ==========
log_step "TEST 2/8: Register Bob"
BOB=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  --data "{\"username\":\"$BOB_USER\",\"email\":\"$BOB_EMAIL\",\"password\":\"pass123\",\"passwordConfirm\":\"pass123\"}")

BOB_ID=$(echo "$BOB" | jq -r '.user.id // empty' 2>/dev/null)
BOB_RESP_CODE=$(echo "$BOB" | jq -r '.success' 2>/dev/null)

if [ "$BOB_RESP_CODE" = "true" ] && [ -n "$BOB_ID" ]; then
  log_success "Bob registered"
else
  log_error "Bob registration failed"
  echo "Response: $BOB"
  exit 1
fi

# ========== TEST 3: Login Alice ==========
log_step "TEST 3/8: Login Alice and get token"
LOGIN=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  --data "{\"email\":\"$ALICE_EMAIL\",\"password\":\"pass123\"}")

TOKEN=$(echo "$LOGIN" | jq -r '.token // empty' 2>/dev/null)
LOGIN_RESP_CODE=$(echo "$LOGIN" | jq -r '.success' 2>/dev/null)

if [ "$LOGIN_RESP_CODE" = "true" ] && [ -n "$TOKEN" ]; then
  log_success "Alice logged in"
else
  log_error "Alice login failed"
  echo "Response: $LOGIN"
  exit 1
fi

# ========== TEST 4: Create Conversation ==========
log_step "TEST 4/8: Create conversation"
CONV=$(curl -s -X POST $BASE_URL/api/conversations \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"participantId\":\"$BOB_ID\"}")

CONV_ID=$(echo "$CONV" | jq -r '.conversation._id // empty' 2>/dev/null)
CONV_RESP_CODE=$(echo "$CONV" | jq -r '.success' 2>/dev/null)

if [ "$CONV_RESP_CODE" = "true" ] && [ -n "$CONV_ID" ]; then
  log_success "Conversation created"
else
  log_error "Conversation creation failed"
  echo "Response: $CONV"
  exit 1
fi

# ========== TEST 5: Send Message ==========
log_step "TEST 5/8: Send message via REST API"
MSG=$(curl -s -X POST $BASE_URL/api/messages \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"conversationId\":\"$CONV_ID\",\"content\":\"Test message\"}")

MSG_RESP_CODE=$(echo "$MSG" | jq -r '.success' 2>/dev/null)
MSG_ID=$(echo "$MSG" | jq -r '.data._id // empty' 2>/dev/null)

if [ "$MSG_RESP_CODE" = "true" ] && [ -n "$MSG_ID" ]; then
  log_success "Message sent"
else
  log_error "Message send failed"
  echo "Response: $MSG"
fi

# ========== TEST 6: Get Online Users ==========
log_step "TEST 6/8: Get online users (Redis)"
ONLINE=$(curl -s -X GET $BASE_URL/api/users/online \
  -H "Authorization: Bearer $TOKEN")

ONLINE_RESP_CODE=$(echo "$ONLINE" | jq -r '.success' 2>/dev/null)
ONLINE_USERS=$(echo "$ONLINE" | jq -r '.users // empty' 2>/dev/null)

if [ "$ONLINE_RESP_CODE" = "true" ] && [ -n "$ONLINE_USERS" ]; then
  log_success "Online users endpoint working"
else
  log_error "Online users endpoint failed"
  echo "Response: $ONLINE"
fi

# ========== TEST 7: Check User Online Status ==========
log_step "TEST 7/8: Check user online status"
STATUS=$(curl -s -X GET $BASE_URL/api/users/$BOB_ID/online-status \
  -H "Authorization: Bearer $TOKEN")

STATUS_RESP_CODE=$(echo "$STATUS" | jq -r '.success' 2>/dev/null)
STATUS_IS_ONLINE=$(echo "$STATUS" | jq -r '.isOnline' 2>/dev/null)

if [ "$STATUS_RESP_CODE" = "true" ] && [ -n "$STATUS_IS_ONLINE" ]; then
  log_success "User status endpoint working"
else
  log_error "User status endpoint failed"
  echo "Response: $STATUS"
fi

# ========== TEST 8: Retrieve Messages ==========
log_step "TEST 8/8: Retrieve messages"
GET_MSG=$(curl -s -X GET $BASE_URL/api/messages/$CONV_ID \
  -H "Authorization: Bearer $TOKEN")

GET_RESP_CODE=$(echo "$GET_MSG" | jq -r '.success' 2>/dev/null)
GET_MSG_COUNT=$(echo "$GET_MSG" | jq -r '.data | length' 2>/dev/null)

if [ "$GET_RESP_CODE" = "true" ] && [ "$GET_MSG_COUNT" -ge 0 ]; then
  log_success "Message retrieval working"
else
  log_error "Message retrieval failed"
  echo "Response: $GET_MSG"
fi

# ========== FINAL SUMMARY ==========
echo ""
log_step "═══════════════════════════════════════════════════════════════"
log_step "Test Results"
log_step "═══════════════════════════════════════════════════════════════"
echo -e "Passed: ${GREEN}$passed${NC}"
echo -e "Failed: ${RED}$failed${NC}"

if [ $failed -eq 0 ]; then
  log_success "ALL TESTS PASSED! ✓✓✓"
  exit 0
else
  log_error "$failed test(s) failed"
  exit 1
fi
