#!/bin/bash

# ChatForge Phase 4 - Complete Test Suite (All 8 Tests)
# Fixed to match actual endpoint responses

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
ALICE=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  --data "{\"username\":\"$ALICE_USER\",\"email\":\"$ALICE_EMAIL\",\"password\":\"pass123\",\"passwordConfirm\":\"pass123\"}")
ALICE_CODE=$(echo "$ALICE" | tail -1)
ALICE_RESP=$(echo "$ALICE" | head -1)
ALICE_ID=$(echo "$ALICE_RESP" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ "$ALICE_CODE" = "201" ] && [ -n "$ALICE_ID" ]; then
  log_success "Alice registered"
else
  log_error "Alice registration failed (Code: $ALICE_CODE)"
  exit 1
fi

# ========== TEST 2: Register Bob ==========
log_step "TEST 2/8: Register Bob"
BOB=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  --data "{\"username\":\"$BOB_USER\",\"email\":\"$BOB_EMAIL\",\"password\":\"pass123\",\"passwordConfirm\":\"pass123\"}")
BOB_CODE=$(echo "$BOB" | tail -1)
BOB_RESP=$(echo "$BOB" | head -1)
BOB_ID=$(echo "$BOB_RESP" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ "$BOB_CODE" = "201" ] && [ -n "$BOB_ID" ]; then
  log_success "Bob registered"
else
  log_error "Bob registration failed (Code: $BOB_CODE)"
  exit 1
fi

# ========== TEST 3: Login Alice ==========
log_step "TEST 3/8: Login Alice and get token"
LOGIN=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  --data "{\"email\":\"$ALICE_EMAIL\",\"password\":\"pass123\"}")
LOGIN_CODE=$(echo "$LOGIN" | tail -1)
LOGIN_RESP=$(echo "$LOGIN" | head -1)
TOKEN=$(echo "$LOGIN_RESP" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ "$LOGIN_CODE" = "200" ] && [ -n "$TOKEN" ]; then
  log_success "Alice logged in"
else
  log_error "Alice login failed (Code: $LOGIN_CODE)"
  exit 1
fi

# ========== TEST 4: Create Conversation ==========
log_step "TEST 4/8: Create conversation"
CONV=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/api/conversations \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"participantId\":\"$BOB_ID\"}")
CONV_CODE=$(echo "$CONV" | tail -1)
CONV_RESP=$(echo "$CONV" | head -1)
CONV_ID=$(echo "$CONV_RESP" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ "$CONV_CODE" = "201" ] && [ -n "$CONV_ID" ]; then
  log_success "Conversation created"
  sleep 1  # Allow database to persist
else
  log_error "Conversation creation failed (Code: $CONV_CODE)"
  echo "Response: $CONV_RESP"
  exit 1
fi

# ========== TEST 5: Send Message ==========
log_step "TEST 5/8: Send message via REST API"
MSG=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/api/messages \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"conversationId\":\"$CONV_ID\",\"content\":\"Test message\"}")
MSG_CODE=$(echo "$MSG" | tail -1)
MSG_RESP=$(echo "$MSG" | head -1)

if [ "$MSG_CODE" = "201" ]; then
  log_success "Message sent"
else
  # If this fails, try to debug
  log_error "Message send failed (Code: $MSG_CODE)"
  echo "  Response: $(echo $MSG_RESP | cut -c1-100)..."
  # Don't exit, continue with other tests
fi

# ========== TEST 6: Get Online Users ==========
log_step "TEST 6/8: Get online users (Redis)"
ONLINE=$(curl -s -w "\n%{http_code}" -X GET $BASE_URL/api/users/online \
  -H "Authorization: Bearer $TOKEN")
ONLINE_CODE=$(echo "$ONLINE" | tail -1)
ONLINE_RESP=$(echo "$ONLINE" | head -1)

# Check for "users" field (not "onlineUsers")
if [ "$ONLINE_CODE" = "200" ] && echo "$ONLINE_RESP" | grep -q '"users"'; then
  log_success "Online users endpoint working"
else
  log_error "Online users endpoint failed (Code: $ONLINE_CODE)"
  echo "  Response: $(echo $ONLINE_RESP | cut -c1-100)..."
fi

# ========== TEST 7: Check User Online Status ==========
log_step "TEST 7/8: Check user online status"
STATUS=$(curl -s -w "\n%{http_code}" -X GET $BASE_URL/api/users/$BOB_ID/online-status \
  -H "Authorization: Bearer $TOKEN")
STATUS_CODE=$(echo "$STATUS" | tail -1)
STATUS_RESP=$(echo "$STATUS" | head -1)

if [ "$STATUS_CODE" = "200" ] && echo "$STATUS_RESP" | grep -q '"isOnline"'; then
  log_success "User status endpoint working"
else
  log_error "User status endpoint failed (Code: $STATUS_CODE)"
fi

# ========== TEST 8: Retrieve Messages ==========
log_step "TEST 8/8: Retrieve messages"
GET_MSG=$(curl -s -w "\n%{http_code}" -X GET $BASE_URL/api/messages/$CONV_ID \
  -H "Authorization: Bearer $TOKEN")
GET_CODE=$(echo "$GET_MSG" | tail -1)
GET_RESP=$(echo "$GET_MSG" | head -1)

if [ "$GET_CODE" = "200" ]; then
  log_success "Message retrieval working"
else
  log_error "Message retrieval failed (Code: $GET_CODE)"
fi

# ========== SUMMARY ==========
log_step "\n═══════════════════════════════════════════════════════════════"
log_step "Test Summary:"
echo -e "  ${GREEN}Passed: $passed${NC}"
echo -e "  ${RED}Failed: $failed${NC}"

if [ $failed -eq 0 ]; then
  echo ""
  echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  ✓✓✓ ALL 8 TESTS PASSED ✓✓✓                         ║${NC}"
  echo -e "${GREEN}║  Phase 4 Implementation Complete!                    ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}Some tests failed - details above${NC}"
  exit 1
fi
