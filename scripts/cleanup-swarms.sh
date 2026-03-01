#!/bin/bash
# Cleanup and Reset Swarms
# Usage: ./scripts/cleanup-swarms.sh [--delete-agents] [--delete-tasks]

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

DELETE_AGENTS=false
DELETE_TASKS=false

for arg in "$@"; do
  case $arg in
    --delete-agents)
      DELETE_AGENTS=true
      ;;
    --delete-tasks)
      DELETE_TASKS=true
      ;;
  esac
done

echo ""
log_info "SwarmClaw Cleanup Utility"
echo ""

# Delete cached IDs
if [ -f "$PROJECT_ROOT/.tech-orchestrator-id" ] || \
   [ -f "$PROJECT_ROOT/.business-orchestrator-id" ] || \
   [ -f "$PROJECT_ROOT/.implementation-agent-id" ]; then
  log_info "Removing cached orchestrator IDs..."
  rm -f "$PROJECT_ROOT/.tech-orchestrator-id"
  rm -f "$PROJECT_ROOT/.business-orchestrator-id"
  rm -f "$PROJECT_ROOT/.implementation-agent-id"
  log_success "Cached IDs removed"
  echo ""
fi

# Delete agents
if [ "$DELETE_AGENTS" = true ]; then
  log_warning "Deleting all swarm agents..."

  # Get all agents
  AGENTS=$(curl -s "$SWARMCLAW_URL/api/agents" -H "x-access-key: $ACCESS_KEY")

  # Find swarm agents by name pattern
  SWARM_AGENT_IDS=$(echo "$AGENTS" | jq -r '.agents[] |
    select(.name | test("Tech Lead|Architect|Developer|Programmer|Tester|CTO|Business Director|Product Manager|Market Researcher|Business Strategist|Engineer-Business Liaison|Growth Advisor|Implementation Engineer")) |
    .id')

  if [ -n "$SWARM_AGENT_IDS" ]; then
    echo "$SWARM_AGENT_IDS" | while read -r agent_id; do
      log_info "Deleting agent: $agent_id"
      curl -s -X DELETE "$SWARMCLAW_URL/api/agents/$agent_id" \
        -H "x-access-key: $ACCESS_KEY" > /dev/null
    done
    log_success "Agents deleted"
  else
    log_info "No swarm agents found"
  fi
  echo ""
fi

# Delete tasks
if [ "$DELETE_TASKS" = true ]; then
  log_warning "Deleting all tasks..."

  TASKS=$(curl -s "$SWARMCLAW_URL/api/tasks" -H "x-access-key: $ACCESS_KEY")
  TASK_IDS=$(echo "$TASKS" | jq -r '.tasks[].id' 2>/dev/null || echo "")

  if [ -n "$TASK_IDS" ]; then
    echo "$TASK_IDS" | while read -r task_id; do
      log_info "Deleting task: $task_id"
      curl -s -X DELETE "$SWARMCLAW_URL/api/tasks/$task_id" \
        -H "x-access-key: $ACCESS_KEY" > /dev/null
    done
    log_success "Tasks deleted"
  else
    log_info "No tasks found"
  fi
  echo ""
fi

if [ "$DELETE_AGENTS" = false ] && [ "$DELETE_TASKS" = false ]; then
  log_info "Only cached IDs were removed"
  echo ""
  log_info "To delete agents: $0 --delete-agents"
  log_info "To delete tasks: $0 --delete-tasks"
  log_info "To delete both: $0 --delete-agents --delete-tasks"
  echo ""
fi

log_success "Cleanup complete"
echo ""
