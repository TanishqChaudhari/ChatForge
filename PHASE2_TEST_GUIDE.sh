#!/bin/bash

# ChatForge Phase 2 - API Testing Guide
# ======================================

BASE_URL="http://localhost:8000"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         ChatForge Phase 2 - API Testing Guide                  ║"
echo "║                Complete Test Scenarios                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# PHASE 2 NEW ENDPOINTS
# ============================================================================

echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}PHASE 2 NEW ENDPOINTS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

# 1. Create Test Users (if needed)
echo -e "${YELLOW}1. REGISTER TWO TEST USERS${NC}"
echo -e "${YELLOW}==================================${NC}\n"

echo "User 1 - Alice:"
echo "curl -X POST http://localhost:8000/api/auth/register \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{
    \"username\": \"alice\",
    \"email\": \"alice@example.com\",
    \"password\": \"password123\",
    \"passwordConfirm\": \"password123\"
  }'"

echo -e "\n${RED}➜ SAVE the TOKEN from response${NC}\n"

echo "User 2 - Bob:"
echo "curl -X POST http://localhost:8000/api/auth/register \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{
    \"username\": \"bob\",
    \"email\": \"bob@example.com\",
    \"password\": \"password123\",
    \"passwordConfirm\": \"password123\"
  }'"

echo -e "\n${RED}➜ SAVE this TOKEN too${NC}\n"

# 2. Get current user (from auth/me - existing endpoint)
echo -e "${YELLOW}2. GET CURRENT USER (Protected)${NC}"
echo -e "${YELLOW}==================================${NC}\n"
echo "curl http://localhost:8000/api/auth/me \\"
echo "  -H 'Authorization: Bearer YOUR_TOKEN_HERE'"
echo -e "\nExpected: User data with id, username, email\n"

# 3. Get all users except self
echo -e "${YELLOW}3. GET ALL USERS (Protected)${NC}"
echo -e "${YELLOW}==================================${NC}\n"
echo "curl http://localhost:8000/api/users \\"
echo "  -H 'Authorization: Bearer ALICE_TOKEN'"
echo -e "\nExpected: List of users (should include Bob but not Alice)\n"

# 4. Search users
echo -e "${YELLOW}4. SEARCH USERS by Username (Protected)${NC}"
echo -e "${YELLOW}==================================${NC}\n"
echo "curl 'http://localhost:8000/api/users/search?query=bob' \\"
echo "  -H 'Authorization: Bearer ALICE_TOKEN'"
echo -e "\nExpected: Search results matching 'bob'\n"

# 5. Create conversation
echo -e "${YELLOW}5. CREATE OR GET CONVERSATION (Protected)${NC}"
echo -e "${YELLOW}==================================${NC}\n"
echo "curl -X POST http://localhost:8000/api/conversations \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -H 'Authorization: Bearer ALICE_TOKEN' \\"
echo "  -d '{
    \"participantId\": \"BOB_USER_ID\"
  }'"
echo -e "\nNote: Replace BOB_USER_ID with Bob's actual _id from user creation"
echo -e "Expected: Conversation object with conversation ID${NC}\n"
echo -e "${RED}➜ SAVE the conversation ID${NC}\n"

# 6. Get all conversations for current user
echo -e "${YELLOW}6. GET ALL CONVERSATIONS for Current User (Protected)${NC}"
echo -e "${YELLOW}==================================${NC}\n"
echo "curl http://localhost:8000/api/conversations \\"
echo "  -H 'Authorization: Bearer ALICE_TOKEN'"
echo -e "\nExpected: Array of conversations for Alice\n"

# 7. Get messages from conversation with pagination
echo -e "${YELLOW}7. GET MESSAGES FROM CONVERSATION (Protected)${NC}"
echo -e "${YELLOW}==================================${NC}\n"
echo "curl 'http://localhost:8000/api/conversations/CONVERSATION_ID/messages?page=1&limit=20' \\"
echo "  -H 'Authorization: Bearer ALICE_TOKEN'"
echo -e "\nNote: Replace CONVERSATION_ID with actual conversation ID"
echo -e "Expected: Paginated messages array (will be empty initially)\n"

# 8. Get single conversation
echo -e "${YELLOW}8. GET SINGLE CONVERSATION (Protected)${NC}"
echo -e "${YELLOW}==================================${NC}\n"
echo "curl http://localhost:8000/api/conversations/CONVERSATION_ID \\"
echo "  -H 'Authorization: Bearer ALICE_TOKEN'"
echo -e "\nNote: Replace CONVERSATION_ID with actual ID"
echo -e "Expected: Single conversation object with participants\n"


# ============================================================================
# FULL WORKFLOW TEST
# ============================================================================

echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}FULL WORKFLOW TEST (Step by Step)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

echo "1️⃣  REGISTER USER 1 (Alice)"
echo "   Endpoint: POST /api/auth/register"
echo "   Returns: token (ALICE_TOKEN), user data, password hashed in DB"
echo "   ✓ Alice account created, Token saved\n"

echo "2️⃣  REGISTER USER 2 (Bob)"
echo "   Endpoint: POST /api/auth/register"
echo "   Returns: token (BOB_TOKEN), user data"
echo "   ✓ Bob account created, Token saved\n"

echo "3️⃣  ALICE GETS ALL USERS"
echo "   Endpoint: GET /api/users"
echo "   Header: Authorization: Bearer ALICE_TOKEN"
echo "   Returns: [Bob's user object, ...other users]"
echo "   ✓ Alice can see Bob in user list\n"

echo "4️⃣  ALICE SEARCHES FOR BOB"
echo "   Endpoint: GET /api/users/search?query=bob"
echo "   Header: Authorization: Bearer ALICE_TOKEN"
echo "   Returns: [Bob's user object]"
echo "   ✓ Search filter works\n"

echo "5️⃣  ALICE CREATES CONVERSATION WITH BOB"
echo "   Endpoint: POST /api/conversations"
echo "   Body: { participantId: BOB_USER_ID }"
echo "   Header: Authorization: Bearer ALICE_TOKEN"
echo "   Returns: conversation object with participants, isEmpty: true"
echo "   ✓ Conversation created with ID, stored in DB\n"

echo "6️⃣  ALICE FETCHES HER CONVERSATIONS"
echo "   Endpoint: GET /api/conversations"
echo "   Header: Authorization: Bearer ALICE_TOKEN"
echo "   Returns: [{ conv with Bob, participants: [Alice, Bob] }]"
echo "   ✓ Can see the conversation\n"

echo "7️⃣  BOB FETCHES HIS CONVERSATIONS"
echo "   Endpoint: GET /api/conversations"
echo "   Header: Authorization: Bearer BOB_TOKEN"
echo "   Returns: [{ same conversation with Alice }]"
echo "   ✓ Both see the same conversation\n"

echo "8️⃣  ALICE FETCHES MESSAGES (empty initially)"
echo "   Endpoint: GET /api/conversations/CONV_ID/messages"
echo "   Header: Authorization: Bearer ALICE_TOKEN"
echo "   Returns: { messages: [], total: 0, pages: 0 }"
echo "   ✓ Pagination working\n"

echo "9️⃣  ALICE TRIES TO CREATE SAME CONVERSATION AGAIN"
echo "   Returns: same conversation (idempotent)"
echo "   ✓ Prevents duplicate conversations\n"

echo "🔟 ALICE TRIES TO MESSAGE HERSELF (should fail)"
echo "   Error: 400 - Cannot create conversation with yourself"
echo "   ✓ Validation working\n"


# ============================================================================
# DATA MODELS
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}DATABASE MODELS STRUCTURE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

echo "USER MODEL (existing):"
echo "├── _id: ObjectId"
echo "├── username: String"
echo "├── email: String"
echo "├── password: String (hashed)"
echo "├── createdAt: Date"
echo "└── updatedAt: Date\n"

echo "CONVERSATION MODEL (new):"
echo "├── _id: ObjectId"
echo "├── participants: [ObjectId] (2 users for 1-to-1)"
echo "├── lastMessage: ObjectId (ref to Message)"
echo "├── lastMessageAt: Date"
echo "├── createdAt: Date"
echo "└── updatedAt: Date\n"

echo "MESSAGE MODEL (new):"
echo "├── _id: ObjectId"
echo "├── conversationId: ObjectId (ref)"
echo "├── senderId: ObjectId (ref to User)"
echo "├── content: String"
echo "├── status: 'sent'|'delivered'|'read'"
echo "├── readAt: Date|null"
echo "├── deliveredAt: Date"
echo "├── createdAt: Date"
echo "└── updatedAt: Date\n"


# ============================================================================
# PROTECTION & SECURITY
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}SECURITY FEATURES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

echo "✓ All /api/users/* endpoints: Protected with JWT"
echo "✓ All /api/conversations/* endpoints: Protected with JWT"
echo "✓ Conversation participants verified: Only members can access messages"
echo "✓ Self-message prevention: Can't create conv with self"
echo "✓ Idempotent conversations: Same conv returned if exists"
echo "✓ Messages always linked to sender & conversation"
echo "✓ Status tracking: sent → delivered → read\n"


# ============================================================================
# PAGINATION
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}PAGINATION FOR MESSAGES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

echo "Endpoint: GET /api/conversations/:id/messages"
echo "Query params:"
echo "  ?page=1             (default: 1)"
echo "  &limit=20           (default: 20)"
echo ""
echo "Examples:"
echo "  /messages?page=1&limit=20     (first 20 messages)"
echo "  /messages?page=2&limit=20     (next 20 messages)"
echo "  /messages?page=1&limit=50     (first 50 messages)"
echo ""
echo "Response includes:"
echo "  - messages: [array of 20 messages, sorted by date]"
echo "  - pagination: { total, page, pages, limit }"
echo "  - count: number of messages in this page\n"


# ============================================================================
# ERROR SCENARIOS
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}ERROR HANDLING TESTS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

echo "Test 1: No JWT Token"
echo "curl http://localhost:8000/api/users"
echo "Expected: 401 - No token provided\n"

echo "Test 2: Invalid JWT Token"
echo "curl http://localhost:8000/api/users \\"
echo "  -H 'Authorization: Bearer invalid_token'"
echo "Expected: 401 - Invalid token\n"

echo "Test 3: Access another user's conversation"
echo "Alice tries to access conversation only Bob is in"
echo "Expected: 403 - Not a participant\n"

echo "Test 4: Non-existent User ID for conversation"
echo "curl -X POST http://localhost:8000/api/conversations \\"
echo "  -d '{\"participantId\": \"invalid_id\"}'"
echo "Expected: 404 - User not found\n"

echo "Test 5: Message pagination with invalid page"
echo "/messages?page=999&limit=20"
echo "Expected: 200 - Empty messages array\n"


# ============================================================================
# ROUTES SUMMARY
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}ALL PHASE 2 ROUTES SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"

echo "┌─ PHASE 1 (Existing) ─────────────────────────────────────────────┐"
echo "│ POST   /api/auth/register        - Create account               │"
echo "│ POST   /api/auth/login           - Login & get token            │"
echo "│ GET    /api/auth/me              - Get current user (protected) │"
echo "│ GET    /health                   - Server health check          │"
echo "└──────────────────────────────────────────────────────────────────┘\n"

echo "┌─ PHASE 2 (New) ──────────────────────────────────────────────────┐"
echo "│ Users Endpoints:                                                │"
echo "│ GET    /api/users                - Get all users (protected)   │"
echo "│ GET    /api/users/search?q=...   - Search users (protected)    │"
echo "│                                                                  │"
echo "│ Conversation Endpoints:                                          │"
echo "│ POST   /api/conversations        - Create/get 1-to-1 (protect) │"
echo "│ GET    /api/conversations        - Get user's conversations     │"
echo "│ GET    /api/conversations/:id    - Get single conversation      │"
echo "│ DELETE /api/conversations/:id    - Delete conversation          │"
echo "│                                                                  │"
echo "│ Message Endpoints:                                               │"
echo "│ GET    /api/conversations/:id/messages - Get with pagination    │"
echo "│        (Query: ?page=1&limit=20)                                │"
echo "└──────────────────────────────────────────────────────────────────┘\n"

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Phase 2 - Users & Conversations Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"

echo "Next Phase: Messaging & Real-time (Phase 3)"
echo "  - Send messages endpoint"
echo "  - Socket.io real-time events"
echo "  - Message status updates"
echo "  - Typing indicators"
echo "  - Read receipts\n"
