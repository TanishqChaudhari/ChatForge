#!/bin/bash

# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  ChatForge - Clean Database Script                                         ║
# ║  Use this to delete test data and start fresh                              ║
# ╚════════════════════════════════════════════════════════════════════════════╝

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
  echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC} $1"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_warning() {
  echo -e "${RED}⚠${NC}  $1"
}

print_success() {
  echo -e "${GREEN}✓${NC}  $1"
}

print_info() {
  echo -e "${YELLOW}ℹ${NC}  $1"
}

# ============================================================================
# MENU
# ============================================================================

print_header "ChatForge Database Cleanup Tool"

echo "Choose an option:"
echo ""
echo "1) Delete all test data (users, conversations, messages) - KEEP database"
echo "2) Drop entire 'chatforge' database - DELETE everything"
echo "3) View current data (don't delete)"
echo "4) Cancel"
echo ""
read -p "Enter choice (1-4): " choice

case $choice in
  1)
    print_header "Option 1: Delete All Collections"
    print_warning "This will DELETE all users, conversations, and messages"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
      mongosh <<EOF
use chatforge
db.users.deleteMany({})
print("✓ Deleted all users")
db.conversations.deleteMany({})
print("✓ Deleted all conversations")
db.messages.deleteMany({})
print("✓ Deleted all messages")
EOF
      print_success "All test data deleted!"
      print_info "Database is now empty but still exists"
    else
      print_info "Cancelled"
    fi
    ;;
    
  2)
    print_header "Option 2: Drop Entire Database"
    print_warning "This will PERMANENTLY DELETE the entire 'chatforge' database"
    read -p "Are you absolutely sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
      read -p "Type 'DELETE' to confirm: " confirm2
      if [ "$confirm2" = "DELETE" ]; then
        mongosh <<EOF
use chatforge
db.dropDatabase()
print("✓ Database dropped!")
EOF
        print_success "Database completely deleted!"
        print_info "When you restart the server, new database will be created"
      else
        print_info "Cancelled - did not type DELETE"
      fi
    else
      print_info "Cancelled"
    fi
    ;;
    
  3)
    print_header "Option 3: View Current Data"
    mongosh <<EOF
use chatforge
print("=== USERS ===")
db.users.countDocuments() > 0 ? db.users.find().pretty() : print("No users")
print("\n=== CONVERSATIONS ===")
db.conversations.countDocuments() > 0 ? db.conversations.find().pretty() : print("No conversations")
print("\n=== MESSAGES ===")
db.messages.countDocuments() > 0 ? db.messages.find().pretty() : print("No messages")
print("\n=== SUMMARY ===")
print("Users: " + db.users.countDocuments())
print("Conversations: " + db.conversations.countDocuments())
print("Messages: " + db.messages.countDocuments())
EOF
    ;;
    
  4)
    print_info "Cancelled"
    exit 0
    ;;
    
  *)
    print_warning "Invalid choice"
    exit 1
    ;;
esac

echo ""
print_header "Done!"
