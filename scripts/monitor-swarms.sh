#!/bin/bash
# Monitor Active Swarm Tasks
# Usage: ./scripts/monitor-swarms.sh [--follow]

set -e

SWARMCLAW_URL="${SWARMCLAW_URL:-http://localhost:3456}"
ACCESS_KEY="${SWARMCLAW_ACCESS_KEY:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

FOLLOW=false
if [[ "$1" == "--follow" ]] || [[ "$1" == "-f" ]]; then
  FOLLOW=true
fi

show_status() {
  clear
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║  SwarmClaw: Active Tasks Monitor                           ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""

  # Get all tasks
  TASKS=$(curl -s "$SWARMCLAW_URL/api/tasks" -H "x-access-key: $ACCESS_KEY" 2>/dev/null)

  if [ $? -ne 0 ]; then
    log_error "Failed to connect to SwarmClaw at $SWARMCLAW_URL"
    return 1
  fi

  # Parse tasks
  TASK_COUNT=$(echo "$TASKS" | jq -r '.tasks | length' 2>/dev/null || echo "0")

  if [ "$TASK_COUNT" = "0" ]; then
    log_info "No active tasks"
    echo ""
    return 0
  fi

  # Show each task
  echo "$TASKS" | jq -r '.tasks[] |
    "\(.id)|\(.title)|\(.status)|\(.agentId)|\(.progress // "N/A")|\(.result // "" | .[0:50])"' | \
  while IFS='|' read -r id title status agent_id progress result; do
    # Status color
    case "$status" in
      "completed"|"done")
        STATUS_COLOR="$GREEN"
        STATUS_ICON="✓"
        ;;
      "running"|"in_progress")
        STATUS_COLOR="$BLUE"
        STATUS_ICON="▶"
        ;;
      "failed"|"error")
        STATUS_COLOR="$RED"
        STATUS_ICON="✗"
        ;;
      "queued"|"pending")
        STATUS_COLOR="$YELLOW"
        STATUS_ICON="⏳"
        ;;
      *)
        STATUS_COLOR="$NC"
        STATUS_ICON="○"
        ;;
    esac

    echo -e "${STATUS_COLOR}${STATUS_ICON}${NC} ${BLUE}${title}${NC}"
    echo "  ID: $id"
    echo "  Agent: $agent_id"
    echo "  Status: ${STATUS_COLOR}${status}${NC}"
    [ "$progress" != "N/A" ] && echo "  Progress: $progress"
    [ -n "$result" ] && echo "  Result: ${result}..."
    echo ""
  done

  echo "─────────────────────────────────────────────────────────────"
  echo "Total tasks: $TASK_COUNT"
  echo ""

  if [ "$FOLLOW" = true ]; then
    echo "Refreshing in 5 seconds... (Ctrl+C to stop)"
  fi
}

if [ "$FOLLOW" = true ]; then
  while true; do
    show_status
    sleep 5
  done
else
  show_status
fi
