#!/bin/bash

# ChatForge Phase 4 - Simple Direct Test
# Avoids heredoc syntax issues

BASE_URL="http://localhost:8000"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

passed=0
failed=0

echo "ChatForge Phase 4 - Test Suite"
echo "=============================="
echo ""

TS=$(date +%s%N)
ALICE_EMAIL="alice_$TS@test.com"
BOB_EMAIL="bob_$TS@test.com"

# TEST 1: Register Alice
echo -n "TEST 1: Register Alice... "
A=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/api/auth/register -H "Content-Type: application/json" --data "{\"username\":\"alice_$TS\",\"email\":\"$ALICE_EMAIL\",\"password\":\"test123\",\"passwordConfirm\":\"test123\"}")
ACODE=$(echo "$A" | tail -1)
ARESP=$(echo "$A" | head -1)
ALICE_ID=$(echo "$ARESP" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ "$ACODE" = "201" ] && [ -n "$ALICE_ID" ]; then
  echo -e "${GREEN}✓${NC}"
  ((passed++))
else
  echo -e "${RED}✗${NC}"
  echo "Code: $ACODE, Response: $ARESP"
  ((failed++))
  exit 1
fi

# TEST 2: Register Bob
echo -n "TEST 2: Register Bob... "
B=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/api/auth/register -H "Content-Type: application/json" --data "{\"username\":\"bob_$TS\",\"email\":\"$BOB_EMAIL\",\"password\":\"test123\",\"passwordConfirm\":\"test123\"}")
BCODE=$(echo "$B" | tail -1)
BRESP=$(echo "$B" | head -1)
BOB_ID=$(echo "$BRESP" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ "$BCODE" = "201" ] && [ -n "$BOB_ID" ]; then
  echo -e "${GREEN}✓${NC}"
  ((passed++))
else
  echo -e "${RED}✗${NC}"
  echo "Code: $BCODE, Response: $BRESP"
  ((failed++))
  exit 1
fi

# TEST 3: Login Alice
echo -n "TEST 3: Login Alice... "
L=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/api/auth/login -H "Content-Type: application/json" --data "{\"email\":\"$ALICE_EMAIL\",\"password\":\"test123\"}")
LCODE=$(echo "$L" | tail -1)
LRESP=$(echo "$L" | head -1)
TOKEN=$(echo "$LRESP" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ "$LCODE" = "200" ] && [ -n "$TOKEN" ]; then
  echo -e "${GREEN}✓${NC}"
  ((passed++))
else
  echo -e "${RED}✗${NC}"
  ((failed++))
  exit 1
fi

# TEST 4: Create Conversation
echo -n "TEST 4: Create Conversation... "
C=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/api/conversations -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" --data "{\"participantId\":\"$BOB_ID\"}")
CCODE=$(echo "$C" | tail -1)
CRESP=$(echo "$C" | head -1)
CONV_ID=$(echo "$CRESP" | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ "$CCODE" = "201" ] && [ -n "$CONV_ID" ]; then
  echo -e "${GREEN}✓${NC}"
  echo "  Conversation ID: $CONV_ID"
  ((passed++))
  
  # Verify conversation was created
  sleep 1
  VERIFY=$(curl -s -X GET $BASE_URL/api/conversations -H "Authorization: Bearer $TOKEN")
  if echo "$VERIFY" | grep -q "$CONV_ID"; then
    echo "  ✓ Conversation verified in list"
  else
    echo "  ⚠ WARNING: Conversation not found in list!"
  fi
else
  echo -e "${RED}✗${NC}"
  echo "Code: $CCODE"
  echo "Full response: $CRESP"
  ((failed++))
  # Continue anyway to see remaining tests
fi

# TEST 5: Send Message
echo -n "TEST 5: Send Message... "
PAYLOAD="{\"conversationId\":\"$CONV_ID\",\"content\":\"Test message from Phase 4\"}"
M=$(curl -s -w "\n%{http_code}" -X POST $BASE_URL/api/messages -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" --data "$PAYLOAD")
MCODE=$(echo "$M" | tail -1)
MRESP=$(echo "$M" | head -1)

if [ "$MCODE" = "201" ] && echo "$MRESP" | grep -q "sent"; then
  echo -e "${GREEN}✓${NC}"
  ((passed++))
else
  echo -e "${RED}✗${NC}"
  echo "Code: $MCODE"
  echo "Payload: $PAYLOAD"
  echo "Response: $MRESP"
  ((failed++))
fi

# TEST 6: Get Online Users
echo -n "TEST 6: Online Users Endpoint... "
O=$(curl -s -w "\n%{http_code}" -X GET $BASE_URL/api/users/online -H "Authorization: Bearer $TOKEN")
OCODE=$(echo "$O" | tail -1)
if [ "$OCODE" = "200" ]; then
  echo -e "${GREEN}✓${NC}"
  ((passed++))
else
  echo -e "${RED}✗${NC}"
  ((failed++))
fi

# TEST 7: Check User Status
echo -n "TEST 7: User Status Endpoint... "
S=$(curl -s -w "\n%{http_code}" -X GET $BASE_URL/api/users/$BOB_ID/online-status -H "Authorization: Bearer $TOKEN")
SCODE=$(echo "$S" | tail -1)
if [ "$SCODE" = "200" ]; then
  echo -e "${GREEN}✓${NC}"
  ((passed++))
else
  echo -e "${RED}✗${NC}"
  ((failed++))
fi

# TEST 8: Get Messages
echo -n "TEST 8: Retrieve Messages... "
G=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/messages/$CONV_ID" -H "Authorization: Bearer $TOKEN")
GCODE=$(echo "$G" | tail -1)
if [ "$GCODE" = "200" ]; then
  echo -e "${GREEN}✓${NC}"
  ((passed++))
else
  echo -e "${RED}✗${NC}"
  ((failed++))
fi

echo ""
echo "Results: $passed passed, $failed failed"

if [ $failed -eq 0 ]; then
  echo -e "${GREEN}✓✓✓ ALL TESTS PASSED! ✓✓✓${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
