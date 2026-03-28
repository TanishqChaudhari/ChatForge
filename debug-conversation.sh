#!/bin/bash

# Debug script to see exact responses

BASE_URL="http://localhost:8000"

echo "=== DEBUGGING: Full Response Bodies ===="
echo ""

# Register user
echo "1. Registering user..."
TS=$(date +%s%N)
ALICE=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  --data "{\"username\":\"debug_$TS\",\"email\":\"debug_$TS@test.com\",\"password\":\"password123\",\"passwordConfirm\":\"password123\"}")

echo "Full Alice Registration Response:"
echo "$ALICE" | jq . 2>/dev/null || echo "$ALICE"

echo ""
echo "Extracting..."
ALICE_ID=$(echo "$ALICE" | jq -r '.id // .data.id // .user.id // .userId // empty' 2>/dev/null)
TOKEN=$(echo "$ALICE" | jq -r '.token // .data.token // .accessToken // empty' 2>/dev/null)

echo "Alice ID: $ALICE_ID"
echo "Token: ${TOKEN:0:30}..."

# Register second user without token yet
echo ""
echo "2. Registering second user..."
BOB=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  --data "{\"username\":\"bob_$TS\",\"email\":\"bob_$TS@test.com\",\"password\":\"password123\",\"passwordConfirm\":\"password123\"}")

echo "Full Bob Registration Response:"
echo "$BOB" | jq . 2>/dev/null || echo "$BOB"

BOB_ID=$(echo "$BOB" | jq -r '.id // .data.id // .user.id // .userId // empty' 2>/dev/null)
echo "Bob ID: $BOB_ID"

echo ""
echo "=== Now trying to create conversation with extracted values ==="
echo "Using Token: ${TOKEN:0:30}..."
echo "Using Bob ID: $BOB_ID"

# Create conversation
echo ""
echo "3. Creating conversation..."
CONV=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/conversations \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"participantId\":\"$BOB_ID\"}")

CONV_CODE=$(echo "$CONV" | grep "HTTP_STATUS" | cut -d: -f2)
CONV_RESP=$(echo "$CONV" | head -1)

echo "Status Code: $CONV_CODE"
echo "Full Response:"
echo "$CONV_RESP" | jq . 2>/dev/null || echo "$CONV_RESP"

echo ""
echo "Extracting conversation ID..."
CONV_ID=$(echo "$CONV_RESP" | jq -r '.conversation._id // ._id // .id // empty' 2>/dev/null)
echo "Conversation ID: $CONV_ID"

if [ -z "$CONV_ID" ]; then
  echo "ERROR: Could not extract conversation ID from response!"
  exit 1
fi

# Try to send message
echo ""
echo "4. Sending message with extracted ID..."
MESSAGE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST $BASE_URL/api/messages \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"conversationId\":\"$CONV_ID\",\"content\":\"Test message\"}")

MSG_CODE=$(echo "$MESSAGE" | grep "HTTP_STATUS" | cut -d: -f2)
MSG_RESP=$(echo "$MESSAGE" | head -1)

echo "Status Code: $MSG_CODE"
echo "Response:"
echo "$MSG_RESP" | jq . 2>/dev/null || echo "$MSG_RESP"
