#!/bin/bash
# Run Implementation Agent (Claude Code Pro)
# Usage: ./scripts/run-implementation.sh /path/to/repo

set -e

SWARMCLAW_URL="${SWARMCLAW_URL:-http://localhost:3456}"
ACCESS_KEY="${SWARMCLAW_ACCESS_KEY:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Get implementation agent ID
AGENT_ID=$(cat "$PROJECT_ROOT/.implementation-agent-id" 2>/dev/null || echo "")
if [ -z "$AGENT_ID" ]; then
  log_error "Implementation Agent ID not found. Run ./scripts/setup-swarms.sh first"
  exit 1
fi

# Get repository path
REPO_PATH="${1:-$(pwd)}"

# Check for plan files
TECH_PLAN="$REPO_PATH/technical-plan.md"
BUSINESS_PLAN="$REPO_PATH/business-strategy.md"

if [ ! -f "$TECH_PLAN" ]; then
  log_warning "Technical plan not found: $TECH_PLAN"
  log_info "Run ./scripts/run-technical-swarm.sh first"
fi

if [ ! -f "$BUSINESS_PLAN" ]; then
  log_warning "Business strategy not found: $BUSINESS_PLAN"
  log_info "Run ./scripts/run-business-swarm.sh first"
fi

# Build task description
TASK="Implement the features and improvements outlined in the technical and business plans.

Repository: $REPO_PATH
Technical Plan: $TECH_PLAN
Business Strategy: $BUSINESS_PLAN

Instructions:
1. **Read Plans**:
   - Read 'technical-plan.md' for technical requirements
   - Read 'business-strategy.md' for business context and priorities
2. **Repository Setup**:
   - Navigate to the repository: $REPO_PATH
   - Review codebase structure and existing patterns
3. **Prioritized Implementation**:
   - Start with MVP features from business plan
   - Follow task breakdown from technical plan
   - Implement changes incrementally
   - Write/update tests as needed
   - Follow existing code style
4. **Validation**:
   - Run tests after each major change
   - Ensure nothing breaks
   - Verify implementations meet requirements
5. **Documentation**:
   - Document significant changes
   - Update README if needed
   - Create 'implementation-log.md' with:
     * Tasks completed
     * Code changes made
     * Tests added/updated
     * Known issues or blockers
     * Next steps

Work autonomously but be careful with:
- Breaking changes
- External API calls
- Data deletion
- System-wide configuration changes

You have Claude Code Pro capabilities. Use them wisely."

log_info "Starting Implementation with Claude Code Pro..."
log_info "Agent ID: $AGENT_ID"
log_info "Repository: $REPO_PATH"
echo ""

# Create a new session for implementation
response=$(curl -s -X POST "$SWARMCLAW_URL/api/sessions" \
  -H "x-access-key: $ACCESS_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"agentId\": \"$AGENT_ID\",
    \"title\": \"Implementation: $(basename $REPO_PATH)\",
    \"cwd\": \"$REPO_PATH\"
  }")

if echo "$response" | jq -e '.ok' > /dev/null 2>&1; then
  session_id=$(echo "$response" | jq -r '.session.id')
  log_success "Session created: $session_id"

  # Send the implementation task
  chat_response=$(curl -s -X POST "$SWARMCLAW_URL/api/sessions/$session_id/chat" \
    -H "x-access-key: $ACCESS_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"content\": $(echo "$TASK" | jq -Rs .)}")

  log_success "Implementation task sent!"
  echo ""
  log_info "Monitor progress in SwarmClaw UI at: $SWARMCLAW_URL"
  log_info "Session: $session_id"
  echo ""
  log_info "Implementation log will be written to: $REPO_PATH/implementation-log.md"
else
  log_error "Failed to create session"
  echo "$response" | jq '.' 2>/dev/null || echo "$response"
  exit 1
fi
