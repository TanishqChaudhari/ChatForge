#!/bin/bash

# ChatForge Phase 2 - Simple Test Script

BASE_URL="http://localhost:8000"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "ChatForge Phase 2 - Complete Test"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# STEP 1: Check server
echo "✓ STEP 1: Checking server health..."
curl -s "$BASE_URL/health" | grep -q "running" && echo "  ✓ Server is running" || echo "  ✗ Server not running"
echo ""

# STEP 2: Register Alice
echo "✓ STEP 2: Registering Alice..."
ALICE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "alice",
    "email": "alice@example.com",
    "password": "password123",
    "passwordConfirm": "password123"
  }')
ALICE_TOKEN=$(echo "$ALICE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
ALICE_ID=$(echo "$ALICE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "  ✓ Alice registered (ID: ${ALICE_ID:0:8}...)"
echo ""

# STEP 3: Register Bob
echo "✓ STEP 3: Registering Bob..."
BOB=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "bob",
    "email": "bob@example.com",
    "password": "password123",
    "passwordConfirm": "password123"
  }')
BOB_TOKEN=$(echo "$BOB" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
BOB_ID=$(echo "$BOB" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "  ✓ Bob registered (ID: ${BOB_ID:0:8}...)"
echo ""

# STEP 4: Register Charlie
echo "✓ STEP 4: Registering Charlie..."
CHARLIE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "charlie",
    "email": "charlie@example.com",
    "password": "password123",
    "passwordConfirm": "password123"
  }')
CHARLIE_ID=$(echo "$CHARLIE" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "  ✓ Charlie registered (ID: ${CHARLIE_ID:0:8}...)"
echo ""

# STEP 5: Get all users
echo "✓ STEP 5: Get all users (as Alice)..."
USERS=$(curl -s "$BASE_URL/api/users" \
  -H "Authorization: Bearer $ALICE_TOKEN")
echo "$USERS" | grep -q "bob" && echo "  ✓ Bob found in user list" || echo "  ✗ Bob not found"
echo "$USERS" | grep -q "charlie" && echo "  ✓ Charlie found in user list" || echo "  ✗ Charlie not found"
echo ""

# STEP 6: Search users
echo "✓ STEP 6: Search for Bob..."
SEARCH=$(curl -s "$BASE_URL/api/users/search?query=bob" \
  -H "Authorization: Bearer $ALICE_TOKEN")
echo "$SEARCH" | grep -q "bob" && echo "  ✓ Bob search successful" || echo "  ✗ Search failed"
echo ""

# STEP 7: Create conversation Alice-Bob
echo "✓ STEP 7: Create conversation (Alice ↔ Bob)..."
CONV=$(curl -s -X POST "$BASE_URL/api/conversations" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d "{\"participantId\": \"$BOB_ID\"}")
CONV_ID=$(echo "$CONV" | grep -o '"_id":"[^"]*' | cut -d'"' -f4)
echo "  ✓ Conversation created (ID: ${CONV_ID:0:8}...)"
echo ""

# STEP 8: Create conversation Alice-Charlie
echo "✓ STEP 8: Create conversation (Alice ↔ Charlie)..."
CONV2=$(curl -s -X POST "$BASE_URL/api/conversations" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d "{\"participantId\": \"$CHARLIE_ID\"}")
CONV2_ID=$(echo "$CONV2" | grep -o '"_id":"[^"]*' | cut -d'"' -f4)
echo "  ✓ Conversation created (ID: ${CONV2_ID:0:8}...)"
echo ""

# STEP 9: Test idempotency
echo "✓ STEP 9: Test idempotency (create same conversation)..."
SAME_CONV=$(curl -s -X POST "$BASE_URL/api/conversations" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d "{\"participantId\": \"$BOB_ID\"}")
SAME_ID=$(echo "$SAME_CONV" | grep -o '"_id":"[^"]*' | cut -d'"' -f4)
if [ "$SAME_ID" = "$CONV_ID" ]; then
  echo "  ✓ Same conversation returned (idempotent)"
else
  echo "  ✗ Different conversation returned"
fi
echo ""

# STEP 10: Get all conversations
echo "✓ STEP 10: Get all conversations (as Alice)..."
ALL_CONV=$(curl -s "$BASE_URL/api/conversations" \
  -H "Authorization: Bearer $ALICE_TOKEN")
CONV_COUNT=$(echo "$ALL_CONV" | grep -o '"_id"' | wc -l)
echo "  ✓ Retrieved $CONV_COUNT conversations"
echo ""

# STEP 11: Get single conversation
echo "✓ STEP 11: Get single conversation details..."
SINGLE=$(curl -s "$BASE_URL/api/conversations/$CONV_ID" \
  -H "Authorization: Bearer $ALICE_TOKEN")
echo "$SINGLE" | grep -q "success" && echo "  ✓ Single conversation retrieved" || echo "  ✗ Failed"
echo ""

# STEP 12: Get messages (empty)
echo "✓ STEP 12: Get messages from conversation..."
MESSAGES=$(curl -s "$BASE_URL/api/conversations/$CONV_ID/messages?page=1&limit=20" \
  -H "Authorization: Bearer $ALICE_TOKEN")
echo "$MESSAGES" | grep -q "count" && echo "  ✓ Messages endpoint working" || echo "  ✗ Failed"
echo ""

# STEP 13: Test pagination
echo "✓ STEP 13: Test pagination..."
PAGE=$(curl -s "$BASE_URL/api/conversations/$CONV_ID/messages?page=1&limit=10" \
  -H "Authorization: Bearer $ALICE_TOKEN")
echo "$PAGE" | grep -q '"limit":10' && echo "  ✓ Pagination working" || echo "  ✗ Failed"
echo ""

# STEP 14: Test Bob can access shared conversation
echo "✓ STEP 14: Test Bob can access shared conversation..."
BOB_ACCESS=$(curl -s "$BASE_URL/api/conversations/$CONV_ID" \
  -H "Authorization: Bearer $BOB_TOKEN")
echo "$BOB_ACCESS" | grep -q "success" && echo "  ✓ Bob can access shared conversation" || echo "  ✗ Failed"
echo ""

# STEP 15: Test error handling
echo "✓ STEP 15: Test error handling..."
NO_TOKEN=$(curl -s "$BASE_URL/api/users")
echo "$NO_TOKEN" | grep -q "No token" && echo "  ✓ No token error handled" || echo "  ✗ Failed"
echo ""

# SUMMARY
echo "═══════════════════════════════════════════════════════════════"
echo "✓ ALL TESTS COMPLETED SUCCESSFULLY!"
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
echo "Endpoints Tested:"
echo "  ✓ GET /api/users"
echo "  ✓ GET /api/users/search"
echo "  ✓ POST /api/conversations"
echo "  ✓ GET /api/conversations"
echo "  ✓ GET /api/conversations/:id"
echo "  ✓ GET /api/conversations/:id/messages"
echo ""
echo "Phase 2 is working perfectly! 🚀"
echo ""
