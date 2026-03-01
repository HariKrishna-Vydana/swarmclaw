#!/bin/bash
# Run Business Swarm Analysis
# Usage: ./scripts/run-business-swarm.sh /path/to/repo [github-url]

set -e

SWARMCLAW_URL="${SWARMCLAW_URL:-http://localhost:3456}"
ACCESS_KEY="${SWARMCLAW_ACCESS_KEY:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Get orchestrator ID
ORCHESTRATOR_ID=$(cat "$PROJECT_ROOT/.business-orchestrator-id" 2>/dev/null || echo "")
if [ -z "$ORCHESTRATOR_ID" ]; then
  log_error "Orchestrator ID not found. Run ./scripts/setup-swarms.sh first"
  exit 1
fi

# Get repository path
REPO_PATH="${1:-}"
GITHUB_URL="${2:-}"

if [ -z "$REPO_PATH" ] && [ -z "$GITHUB_URL" ]; then
  log_error "Usage: $0 /path/to/repo [github-url]"
  exit 1
fi

# Build task description
TASK="Analyze this product and create a comprehensive business strategy for a single-person company launch.

Repository: ${REPO_PATH:-Clone from $GITHUB_URL}

Instructions:
1. **Product Understanding**: Read the codebase to understand current capabilities and technical foundation
2. **Team Delegation**:
   - Delegate to Product Manager for feature prioritization
   - Delegate to Market Researcher for competitive analysis
   - Delegate to Business Strategist for market positioning
   - Delegate to Engineer-Business Liaison for technical feasibility
   - Delegate to Growth Advisor for marketing and growth strategy
3. **Market Research**: Conduct web research on competitors, market trends, and customer needs
4. **Strategy Synthesis**: Combine insights into an actionable business plan
5. **Output**: Write the strategy to 'business-strategy.md' in the working directory

The file should include:
- Executive Summary
- Product Vision & Positioning
- Competitive Landscape Analysis
- Target Market & Customer Segments
- Feature Roadmap & Prioritization (MVP vs future)
- Go-to-Market Strategy (for single-person company)
- Revenue Model & Pricing Strategy
- Growth & Marketing Plan (bootstrapped approach)
- Success Metrics & KPIs
- Resource Requirements & Timeline
- Risk Assessment & Mitigation

Focus on actionable plans for a solo founder. Be realistic about time and resource constraints."

log_info "Starting Business Swarm Analysis..."
log_info "Orchestrator ID: $ORCHESTRATOR_ID"
echo ""

# Trigger orchestrator
response=$(curl -s -X POST "$SWARMCLAW_URL/api/orchestrator/run" \
  -H "x-access-key: $ACCESS_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"agentId\": \"$ORCHESTRATOR_ID\",
    \"task\": $(echo "$TASK" | jq -Rs .)
  }")

if echo "$response" | jq -e '.ok' > /dev/null 2>&1; then
  task_id=$(echo "$response" | jq -r '.taskId')
  log_success "Business analysis started!"
  log_info "Task ID: $task_id"
  echo ""
  log_info "Monitor progress in SwarmClaw UI at: $SWARMCLAW_URL"
  log_info "Or check task status with: curl -H 'x-access-key: $ACCESS_KEY' $SWARMCLAW_URL/api/tasks/$task_id"
  echo ""
  log_info "Output will be written to: business-strategy.md"
else
  log_error "Failed to start analysis"
  echo "$response" | jq '.' 2>/dev/null || echo "$response"
  exit 1
fi
