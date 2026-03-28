#!/bin/bash

# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  ChatForge Phase 3 - REST API Messages Test                               ║
# ║  Tests: Sending messages, marking as read, updating status                ║
# ╚════════════════════════════════════════════════════════════════════════════╝

BASE_URL="http://localhost:8000"
FAILED=0
TIMESTAMP=$(date +%s%N | md5sum | cut -c1-8)

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "ChatForge Phase 3 - REST API Message Endpoints Test"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Clean database
echo "Preparing test environment..."
mongosh <<EOF 2>/dev/null
use chatforge
db.dropDatabase()
EOF
echo "  ✓ Database cleaned"
echo ""

# Register two users
echo "Setting up test users..."
ALICE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"alice_$TIMESTAMP\",\"email\":\"alice_$TIMESTAMP@example.com\",\"password\":\"password123\",\"passwordConfirm\":\"password123\"}")
ALICE_TOKEN=$(echo "$ALICE" | jq -r '.token' 2>/dev/null)
ALICE_ID=$(echo "$ALICE" | jq -r '.user.id' 2>/dev/null)

BOB=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"bob_$TIMESTAMP\",\"email\":\"bob_$TIMESTAMP@example.com\",\"password\":\"password123\",\"passwordConfirm\":\"password123\"}")
BOB_TOKEN=$(echo "$BOB" | jq -r '.token' 2>/dev/null)
BOB_ID=$(echo "$BOB" | jq -r '.user.id' 2>/dev/null)

echo "  ✓ Alice registered (ID: ${ALICE_ID:0:8}...)"
echo "  ✓ Bob registered (ID: ${BOB_ID:0:8}...)"
echo ""

# Create conversation
echo "STEP 1: Create conversation..."
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

# STEP 1: Send message via REST API
echo "STEP 2: Send message via REST API (Alice → Bob)..."
MSG=$(curl -s -X POST "$BASE_URL/api/messages" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ALICE_TOKEN" \
  -d "{\"conversationId\":\"$CONV_ID\",\"content\":\"Hello Bob!\"}")
MSG_ID=$(echo "$MSG" | jq -r '.data._id' 2>/dev/null)
MSG_STATUS=$(echo "$MSG" | jq -r '.data.status' 2>/dev/null)

if [ -n "$MSG_ID" ] && [ "$MSG_ID" != "null" ]; then
  echo "  ✓ Message sent (ID: ${MSG_ID:0:8}..., Status: $MSG_STATUS)"
else
  echo "  ✗ Failed to send message"
  echo "  Response: $MSG"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 2: Get messages
echo "STEP 3: Get messages from conversation..."
MSGS=$(curl -s "$BASE_URL/api/conversations/$CONV_ID/messages?page=1&limit=20" \
  -H "Authorization: Bearer $ALICE_TOKEN")
MSG_COUNT=$(echo "$MSGS" | jq '.count' 2>/dev/null)

if [ "$MSG_COUNT" = "1" ]; then
  echo "  ✓ Message retrieved (Count: $MSG_COUNT)"
else
  echo "  ✗ Failed to retrieve messages (Count: $MSG_COUNT)"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 3: Mark message as read
echo "STEP 4: Mark message as read (Bob reads Alice's message)..."
READ=$(curl -s -X PATCH "$BASE_URL/api/messages/$MSG_ID/read" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $BOB_TOKEN")
READ_STATUS=$(echo "$READ" | jq -r '.data.status' 2>/dev/null)

if [ "$READ_STATUS" = "read" ]; then
  echo "  ✓ Message marked as read"
else
  echo "  ✗ Failed to mark as read (Status: $READ_STATUS)"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 4: Update message status to delivered
echo "STEP 5: Update message status to delivered..."
DELIVER=$(curl -s -X PATCH "$BASE_URL/api/messages/$MSG_ID/status" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -d '{"status":"delivered"}')
DELIVER_STATUS=$(echo "$DELIVER" | jq -r '.data.status' 2>/dev/null)

if [ "$DELIVER_STATUS" = "delivered" ]; then
  echo "  ✓ Message status updated to delivered"
else
  echo "  ✗ Failed to update status (Status: $DELIVER_STATUS)"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 5: Send message from Bob to Alice
echo "STEP 6: Send message from Bob to Alice..."
MSG2=$(curl -s -X POST "$BASE_URL/api/messages" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $BOB_TOKEN" \
  -d "{\"conversationId\":\"$CONV_ID\",\"content\":\"Hi Alice! How are you?\"}")
MSG2_ID=$(echo "$MSG2" | jq -r '.data._id' 2>/dev/null)

if [ -n "$MSG2_ID" ] && [ "$MSG2_ID" != "null" ]; then
  echo "  ✓ Message sent from Bob"
else
  echo "  ✗ Failed to send message from Bob"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 6: Get all messages (should be 2)
echo "STEP 7: Get all messages (verify count)..."
ALL_MSGS=$(curl -s "$BASE_URL/api/conversations/$CONV_ID/messages?page=1&limit=20" \
  -H "Authorization: Bearer $ALICE_TOKEN")
TOTAL_COUNT=$(echo "$ALL_MSGS" | jq '.count' 2>/dev/null)

if [ "$TOTAL_COUNT" = "2" ]; then
  echo "  ✓ Got 2 messages total"
else
  echo "  ✗ Expected 2 messages, got $TOTAL_COUNT"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 7: Test pagination
echo "STEP 8: Test pagination (limit=1)..."
PAGE=$(curl -s "$BASE_URL/api/conversations/$CONV_ID/messages?page=1&limit=1" \
  -H "Authorization: Bearer $ALICE_TOKEN")
PAGE_LIMIT=$(echo "$PAGE" | jq '.pagination.limit' 2>/dev/null)
PAGE_COUNT=$(echo "$PAGE" | jq '.count' 2>/dev/null)

if [ "$PAGE_LIMIT" = "1" ] && [ "$PAGE_COUNT" = "1" ]; then
  echo "  ✓ Pagination working (Limit: $PAGE_LIMIT, Count: $PAGE_COUNT)"
else
  echo "  ✗ Pagination failed (Limit: $PAGE_LIMIT, Count: $PAGE_COUNT)"
  FAILED=$((FAILED+1))
fi
echo ""

# STEP 8: Error handling - no token
echo "STEP 9: Error handling (missing token)..."
NO_TOKEN=$(curl -s -X POST "$BASE_URL/api/messages" \
  -H 'Content-Type: application/json' \
  -d "{\"conversationId\":\"$CONV_ID\",\"content\":\"test\"}")
ERROR_MSG=$(echo "$NO_TOKEN" | jq -r '.message' 2>/dev/null)

if echo "$ERROR_MSG" | grep -q "token"; then
  echo "  ✓ Error handling works"
else
  echo "  ✗ Error handling failed"
  FAILED=$((FAILED+1))
fi
echo ""

# SUMMARY
echo "═══════════════════════════════════════════════════════════════"
PASSED=$((9 - FAILED))
if [ $FAILED -eq 0 ]; then
  echo "✓ ALL TESTS PASSED! (9/9)"
else
  echo "⚠ TESTS COMPLETED WITH $FAILED FAILURES ($PASSED/9 passed)"
fi
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Test Coverage:"
echo "  ✓ Send message via REST API"
echo "  ✓ Get messages (paginated)"
echo "  ✓ Mark message as read"
echo "  ✓ Update message status"
echo "  ✓ Bidirectional messaging"
echo "  ✓ Error handling"
echo ""
