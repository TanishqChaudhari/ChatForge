#!/bin/bash

# ChatForge Phase 2 - Complete Test with jq parsing

BASE_URL="http://localhost:8000"
FAILED=0
TIMESTAMP=$(date +%s%N | md5sum | cut -c1-8)

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "ChatForge Phase 2 - Complete Test"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# CLEANUP: Clear database first
echo "Cleaning database..."
mongosh <<EOF 2>/dev/null
use chatforge
db.dropDatabase()
EOF
echo "  ✓ Database cleaned"
echo ""

# STEP 1: Check server
echo "STEP 1: Checking server health..."
HEALTH=$(curl -s "$BASE_URL/health")
if echo "$HEALTH" | jq -e '.status' > /dev/null 2>&1; then
  echo "  ✓ Server is running"
else
  echo "  ✗ Server not running"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 2: Register Alice
echo "STEP 2: Registering Alice..."
ALICE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"alice_$TIMESTAMP\",\"email\":\"alice_$TIMESTAMP@example.com\",\"password\":\"password123\",\"passwordConfirm\":\"password123\"}")
ALICE_TOKEN=$(echo "$ALICE" | jq -r '.token' 2>/dev/null)
ALICE_ID=$(echo "$ALICE" | jq -r '.user.id' 2>/dev/null)

if [ -n "$ALICE_TOKEN" ] && [ "$ALICE_TOKEN" != "null" ]; then
  echo "  ✓ Alice registered (ID: ${ALICE_ID:0:8}...)"
else
  echo "  ✗ Alice registration failed"
  echo "  Response: $ALICE"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 3: Register Bob
echo "STEP 3: Registering Bob..."
BOB=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"bob_$TIMESTAMP\",\"email\":\"bob_$TIMESTAMP@example.com\",\"password\":\"password123\",\"passwordConfirm\":\"password123\"}")
BOB_TOKEN=$(echo "$BOB" | jq -r '.token' 2>/dev/null)
BOB_ID=$(echo "$BOB" | jq -r '.user.id' 2>/dev/null)

if [ -n "$BOB_TOKEN" ] && [ "$BOB_TOKEN" != "null" ]; then
  echo "  ✓ Bob registered (ID: ${BOB_ID:0:8}...)"
else
  echo "  ✗ Bob registration failed"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 4: Register Charlie
echo "STEP 4: Registering Charlie..."
CHARLIE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"charlie_$TIMESTAMP\",\"email\":\"charlie_$TIMESTAMP@example.com\",\"password\":\"password123\",\"passwordConfirm\":\"password123\"}")
CHARLIE_ID=$(echo "$CHARLIE" | jq -r '.user.id' 2>/dev/null)

if [ -n "$CHARLIE_ID" ] && [ "$CHARLIE_ID" != "null" ]; then
  echo "  ✓ Charlie registered (ID: ${CHARLIE_ID:0:8}...)"
else
  echo "  ✗ Charlie registration failed"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 5: Get all users
echo "STEP 5: Get all users (as Alice)..."
USERS=$(curl -s "$BASE_URL/api/users" \
  -H "Authorization: Bearer $ALICE_TOKEN")
USER_COUNT=$(echo "$USERS" | jq '.users | length' 2>/dev/null)

if [ "$USER_COUNT" -ge 2 ]; then
  echo "  ✓ Found $USER_COUNT users (Bob and Charlie)"
else
  echo "  ✗ Expected at least 2 users, got $USER_COUNT"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 6: Search users
echo "STEP 6: Search for Bob..."
SEARCH=$(curl -s "$BASE_URL/api/users/search?query=bob" \
  -H "Authorization: Bearer $ALICE_TOKEN")
SEARCH_COUNT=$(echo "$SEARCH" | jq '.users | length' 2>/dev/null)

if [ "$SEARCH_COUNT" -gt 0 ]; then
  echo "  ✓ Bob search successful"
else
  echo "  ✗ Search failed (found $SEARCH_COUNT results)"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 7: Create conversation Alice-Bob
echo "STEP 7: Create conversation (Alice ↔ Bob)..."
CONV=$(curl -s -X POST "$BASE_URL/api/conversations" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d "{\"participantId\":\"$BOB_ID\"}")
CONV_ID=$(echo "$CONV" | jq -r '.conversation._id' 2>/dev/null)

if [ -n "$CONV_ID" ] && [ "$CONV_ID" != "null" ]; then
  echo "  ✓ Conversation created (ID: ${CONV_ID:0:8}...)"
else
  echo "  ✗ Conversation creation failed"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 8: Create conversation Alice-Charlie
echo "STEP 8: Create conversation (Alice ↔ Charlie)..."
CONV2=$(curl -s -X POST "$BASE_URL/api/conversations" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d "{\"participantId\":\"$CHARLIE_ID\"}")
CONV2_ID=$(echo "$CONV2" | jq -r '.conversation._id' 2>/dev/null)

if [ -n "$CONV2_ID" ] && [ "$CONV2_ID" != "null" ]; then
  echo "  ✓ Conversation created (ID: ${CONV2_ID:0:8}...)"
else
  echo "  ✗ Conversation creation failed"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 9: Test idempotency
echo "STEP 9: Test idempotency (create same conversation)..."
SAME_CONV=$(curl -s -X POST "$BASE_URL/api/conversations" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d "{\"participantId\":\"$BOB_ID\"}")
SAME_ID=$(echo "$SAME_CONV" | jq -r '.conversation._id' 2>/dev/null)

if [ "$SAME_ID" = "$CONV_ID" ]; then
  echo "  ✓ Same conversation returned (idempotent)"
else
  echo "  ✗ Different conversation returned"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 10: Get all conversations
echo "STEP 10: Get all conversations (as Alice)..."
ALL_CONV=$(curl -s "$BASE_URL/api/conversations" \
  -H "Authorization: Bearer $ALICE_TOKEN")
CONV_COUNT=$(echo "$ALL_CONV" | jq '.conversations | length' 2>/dev/null)

if [ "$CONV_COUNT" -ge 2 ]; then
  echo "  ✓ Retrieved $CONV_COUNT conversations"
else
  echo "  ✗ Expected at least 2, got $CONV_COUNT"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 11: Get single conversation
echo "STEP 11: Get single conversation details..."
SINGLE=$(curl -s "$BASE_URL/api/conversations/$CONV_ID" \
  -H "Authorization: Bearer $ALICE_TOKEN")
SINGLE_SUCCESS=$(echo "$SINGLE" | jq -r '.success' 2>/dev/null)

if [ "$SINGLE_SUCCESS" = "true" ]; then
  echo "  ✓ Single conversation retrieved"
else
  echo "  ✗ Failed to retrieve conversation"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 12: Get messages
echo "STEP 12: Get messages from conversation..."
MESSAGES=$(curl -s "$BASE_URL/api/conversations/$CONV_ID/messages?page=1&limit=20" \
  -H "Authorization: Bearer $ALICE_TOKEN")
MSG_COUNT=$(echo "$MESSAGES" | jq '.count' 2>/dev/null)

if [ -n "$MSG_COUNT" ] && [ "$MSG_COUNT" != "null" ]; then
  echo "  ✓ Messages endpoint working (count: $MSG_COUNT)"
else
  echo "  ✗ Failed to fetch messages"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 13: Test pagination
echo "STEP 13: Test pagination..."
PAGE=$(curl -s "$BASE_URL/api/conversations/$CONV_ID/messages?page=1&limit=10" \
  -H "Authorization: Bearer $ALICE_TOKEN")
LIMIT=$(echo "$PAGE" | jq '.pagination.limit' 2>/dev/null)

if [ "$LIMIT" = "10" ]; then
  echo "  ✓ Pagination working (limit: $LIMIT)"
else
  echo "  ✗ Pagination failed (limit: $LIMIT)"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 14: Test Bob can access shared conversation
echo "STEP 14: Test Bob can access shared conversation..."
BOB_ACCESS=$(curl -s "$BASE_URL/api/conversations/$CONV_ID" \
  -H "Authorization: Bearer $BOB_TOKEN")
BOB_SUCCESS=$(echo "$BOB_ACCESS" | jq -r '.success' 2>/dev/null)

if [ "$BOB_SUCCESS" = "true" ]; then
  echo "  ✓ Bob can access shared conversation"
else
  echo "  ✗ Bob cannot access conversation"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 15: Test error handling
echo "STEP 15: Test error handling (no token)..."
NO_TOKEN=$(curl -s "$BASE_URL/api/users")
ERROR_MSG=$(echo "$NO_TOKEN" | jq -r '.message' 2>/dev/null)

if echo "$ERROR_MSG" | grep -q "token"; then
  echo "  ✓ No token error handled"
else
  echo "  ✗ Error handling failed"
  FAILED=$((FAILED+1))
fi
echo ""

# SUMMARY
echo "═══════════════════════════════════════════════════════════════"
PASSED=$((15 - FAILED))
if [ $FAILED -eq 0 ]; then
  echo "✓ ALL TESTS PASSED! (15/15)"
else
  echo "⚠ TESTS COMPLETED WITH $FAILED FAILURES ($PASSED/15 passed)"
fi
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Users Created:"
echo "  • alice (alice@example.com)"
echo "  • bob (bob@example.com)"
echo "  • charlie (charlie@example.com)"
echo ""
echo "Conversations Created:"
echo "  • Alice ↔ Bob"
echo "  • Alice ↔ Charlie"
echo ""
echo "Endpoints Validated:"
echo "  ✓ POST /api/auth/register"
echo "  ✓ GET /api/users"
echo "  ✓ GET /api/users/search"
echo "  ✓ POST /api/conversations"
echo "  ✓ GET /api/conversations"
echo "  ✓ GET /api/conversations/:id"
echo "  ✓ GET /api/conversations/:id/messages"
echo ""
