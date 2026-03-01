#!/bin/bash
# Run Technical Swarm Analysis
# Usage: ./scripts/run-technical-swarm.sh /path/to/repo [github-url]

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
ORCHESTRATOR_ID=$(cat "$PROJECT_ROOT/.tech-orchestrator-id" 2>/dev/null || echo "")
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
TASK="Analyze the codebase and create a comprehensive technical plan.

Repository: ${REPO_PATH:-Clone from $GITHUB_URL}

Instructions:
1. **Codebase Analysis**: Read the repository structure, technology stack, and existing implementation
2. **Team Delegation**:
   - Delegate to Architect for system design analysis
   - Delegate to Developer for implementation breakdown
   - Delegate to Programmer for code quality review
   - Delegate to Tester for QA strategy
   - Delegate to CTO for strategic technical decisions
3. **Synthesis**: Combine all insights into a cohesive plan
4. **Output**: Write the plan to 'technical-plan.md' in the working directory

The file should include:
- Executive Summary
- System Architecture Analysis
- Task Breakdown (specific, actionable items)
- Implementation Roadmap (prioritized)
- Testing Strategy
- Technical Debt & Improvements
- Risk Assessment
- Resource Estimates

Be thorough and specific. This plan will guide implementation."

log_info "Starting Technical Swarm Analysis..."
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
  log_success "Technical analysis started!"
  log_info "Task ID: $task_id"
  echo ""
  log_info "Monitor progress in SwarmClaw UI at: $SWARMCLAW_URL"
  log_info "Or check task status with: curl -H 'x-access-key: $ACCESS_KEY' $SWARMCLAW_URL/api/tasks/$task_id"
  echo ""
  log_info "Output will be written to: technical-plan.md"
else
  log_error "Failed to start analysis"
  echo "$response" | jq '.' 2>/dev/null || echo "$response"
  exit 1
fi
