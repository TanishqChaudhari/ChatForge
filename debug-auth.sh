#!/bin/bash

# Direct API test to debug registration
echo "Testing registration endpoint..."
echo ""

response=$(curl -s -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "test_debug",
    "email": "debug@test.com",
    "password": "test123",
    "passwordConfirm": "test123"
  }')

echo "Full response:"
echo "$response"
echo ""

# Try to extract ID
id=$(echo "$response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "Extracted ID: $id"
echo ""

# Check if it contains error
if echo "$response" | grep -q "error\|success.*false"; then
  echo "Response indicates error or failure"
else
  echo "Response appears to be success"
fi
