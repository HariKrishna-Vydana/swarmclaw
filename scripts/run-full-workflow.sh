#!/bin/bash
# Complete End-to-End Swarm Workflow
# Usage: ./scripts/run-full-workflow.sh /path/to/repo [--skip-implementation]

set -e

SWARMCLAW_URL="${SWARMCLAW_URL:-http://localhost:3456}"
ACCESS_KEY="${SWARMCLAW_ACCESS_KEY:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_step() { echo -e "${MAGENTA}▸${NC} ${CYAN}$1${NC}"; }

REPO_PATH="${1:-}"
SKIP_IMPLEMENTATION=false

if [[ "$2" == "--skip-implementation" ]] || [[ "$1" == "--skip-implementation" ]]; then
  SKIP_IMPLEMENTATION=true
fi

if [ -z "$REPO_PATH" ]; then
  log_error "Usage: $0 /path/to/repo [--skip-implementation]"
  exit 1
fi

if [ -z "$ACCESS_KEY" ]; then
  log_error "SWARMCLAW_ACCESS_KEY not set"
  log_info "Export it with: export SWARMCLAW_ACCESS_KEY=your-key"
  exit 1
fi

# Header
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  SwarmClaw: Full Multi-Agent Workflow                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
log_info "Repository: $REPO_PATH"
log_info "SwarmClaw: $SWARMCLAW_URL"
echo ""

# Step 1: Technical Swarm
log_step "STEP 1/4: Running Technical Swarm Analysis"
echo ""
bash "$SCRIPT_DIR/run-technical-swarm.sh" "$REPO_PATH"
TECH_TASK_ID=$(curl -s "$SWARMCLAW_URL/api/tasks" -H "x-access-key: $ACCESS_KEY" | jq -r '.tasks[0].id' 2>/dev/null || echo "")
echo ""

# Step 2: Business Swarm (run in parallel)
log_step "STEP 2/4: Running Business Swarm Analysis"
echo ""
bash "$SCRIPT_DIR/run-business-swarm.sh" "$REPO_PATH"
BUSINESS_TASK_ID=$(curl -s "$SWARMCLAW_URL/api/tasks" -H "x-access-key: $ACCESS_KEY" | jq -r '.tasks[0].id' 2>/dev/null || echo "")
echo ""

# Step 3: Wait for both swarms to complete
log_step "STEP 3/4: Waiting for Swarm Analyses to Complete"
echo ""
log_info "This may take several minutes depending on repository size..."
log_info "Monitor progress at: $SWARMCLAW_URL"
echo ""

TECH_COMPLETE=false
BUSINESS_COMPLETE=false
WAIT_COUNT=0
MAX_WAIT=180  # 30 minutes max (180 * 10 seconds)

while [ "$TECH_COMPLETE" = false ] || [ "$BUSINESS_COMPLETE" = false ]; do
  if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
    log_error "Timeout waiting for swarms to complete (30 minutes)"
    log_info "Check SwarmClaw UI for status"
    exit 1
  fi

  # Check technical swarm
  if [ "$TECH_COMPLETE" = false ] && [ -n "$TECH_TASK_ID" ]; then
    TECH_STATUS=$(curl -s "$SWARMCLAW_URL/api/tasks/$TECH_TASK_ID" -H "x-access-key: $ACCESS_KEY" | jq -r '.task.status' 2>/dev/null || echo "unknown")
    if [ "$TECH_STATUS" = "completed" ] || [ "$TECH_STATUS" = "done" ]; then
      log_success "Technical swarm completed!"
      TECH_COMPLETE=true
    elif [ "$TECH_STATUS" = "failed" ]; then
      log_error "Technical swarm failed"
      TECH_COMPLETE=true
    fi
  fi

  # Check business swarm
  if [ "$BUSINESS_COMPLETE" = false ] && [ -n "$BUSINESS_TASK_ID" ]; then
    BUSINESS_STATUS=$(curl -s "$SWARMCLAW_URL/api/tasks/$BUSINESS_TASK_ID" -H "x-access-key: $ACCESS_KEY" | jq -r '.task.status' 2>/dev/null || echo "unknown")
    if [ "$BUSINESS_STATUS" = "completed" ] || [ "$BUSINESS_STATUS" = "done" ]; then
      log_success "Business swarm completed!"
      BUSINESS_COMPLETE=true
    elif [ "$BUSINESS_STATUS" = "failed" ]; then
      log_error "Business swarm failed"
      BUSINESS_COMPLETE=true
    fi
  fi

  if [ "$TECH_COMPLETE" = false ] || [ "$BUSINESS_COMPLETE" = false ]; then
    echo -ne "\r${BLUE}⏳${NC} Waiting... ($(($WAIT_COUNT * 10))s elapsed)  "
    sleep 10
    WAIT_COUNT=$((WAIT_COUNT + 1))
  fi
done

echo ""
echo ""

# Check if plan files exist
TECH_PLAN="$REPO_PATH/technical-plan.md"
BUSINESS_PLAN="$REPO_PATH/business-strategy.md"

if [ -f "$TECH_PLAN" ]; then
  log_success "Technical plan generated: $TECH_PLAN"
  TECH_LINES=$(wc -l < "$TECH_PLAN" | tr -d ' ')
  log_info "  └─ $TECH_LINES lines"
else
  log_warning "Technical plan not found at $TECH_PLAN"
fi

if [ -f "$BUSINESS_PLAN" ]; then
  log_success "Business strategy generated: $BUSINESS_PLAN"
  BUSINESS_LINES=$(wc -l < "$BUSINESS_PLAN" | tr -d ' ')
  log_info "  └─ $BUSINESS_LINES lines"
else
  log_warning "Business plan not found at $BUSINESS_PLAN"
fi

echo ""

# Step 4: Implementation (optional)
if [ "$SKIP_IMPLEMENTATION" = true ]; then
  log_warning "Skipping implementation (--skip-implementation flag set)"
  echo ""
  log_info "To run implementation later:"
  echo "  ./scripts/run-implementation.sh $REPO_PATH"
else
  log_step "STEP 4/4: Running Implementation Agent"
  echo ""

  # Ask for confirmation
  echo -e "${YELLOW}⚠${NC} ${YELLOW}Implementation will make code changes to your repository${NC}"
  echo -e "${YELLOW}⚠${NC} ${YELLOW}Ensure you have committed or backed up your code${NC}"
  echo ""
  read -p "Continue with implementation? [y/N] " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/run-implementation.sh" "$REPO_PATH"
  else
    log_info "Implementation skipped by user"
    echo ""
    log_info "To run implementation later:"
    echo "  ./scripts/run-implementation.sh $REPO_PATH"
  fi
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Workflow Complete!                                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log_success "Generated files:"
[ -f "$TECH_PLAN" ] && echo "  - $TECH_PLAN"
[ -f "$BUSINESS_PLAN" ] && echo "  - $BUSINESS_PLAN"
[ -f "$REPO_PATH/implementation-log.md" ] && echo "  - $REPO_PATH/implementation-log.md"
echo ""

log_info "Next steps:"
echo "  1. Review the plans:"
echo "     cat $TECH_PLAN"
echo "     cat $BUSINESS_PLAN"
echo ""
echo "  2. Check implementation log:"
echo "     cat $REPO_PATH/implementation-log.md"
echo ""
echo "  3. Review code changes:"
echo "     cd $REPO_PATH && git diff"
echo ""
