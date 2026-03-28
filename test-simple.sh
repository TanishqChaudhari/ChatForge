#!/bin/bash

# Debug version of Phase 4 test script

BASE_URL="http://localhost:8000"

echo "Testing registration..."
echo ""

# Test 1: Register Alice
echo "1. Registering Alice..."
TIMESTAMP=$(date +%s%N)
ALICE=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"alice_test_$TIMESTAMP\",
    \"email\": \"alice_$TIMESTAMP@test.com\",
    \"password\": \"test123\",
    \"passwordConfirm\": \"test123\"
  }")

echo "Response: $ALICE"
echo ""

ALICE_ID=$(echo "$ALICE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$ALICE_ID" ]; then
  echo "✓ Alice ID: $ALICE_ID"
else
  echo "✗ Failed to get Alice ID"
  exit 1
fi

echo ""
echo "2. Registering Bob..."
BOB=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"bob_test_$TIMESTAMP\",
    \"email\": \"bob_$TIMESTAMP@test.com\",
    \"password\": \"test123\",
    \"passwordConfirm\": \"test123\"
  }")

echo "Response: $BOB"
echo ""

BOB_ID=$(echo "$BOB" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$BOB_ID" ]; then
  echo "✓ Bob ID: $BOB_ID"
else
  echo "✗ Failed to get Bob ID"
  exit 1
fi

echo ""
echo "3. Logging in Alice..."
LOGIN=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"alice_$TIMESTAMP@test.com\",
    \"password\": \"test123\"
  }")

echo "Login response: $LOGIN"
TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$TOKEN" ]; then
  echo "✓ Got token: ${TOKEN:0:20}..."
else
  echo "✗ Failed to get token"
  exit 1
fi

echo ""
echo "All basic tests passed!"
