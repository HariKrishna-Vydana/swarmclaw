#!/bin/bash
# SwarmClaw Multi-Agent Setup Script
# This script sets up the technical and business agent swarms

set -e

# Configuration
SWARMCLAW_URL="${SWARMCLAW_URL:-http://localhost:3456}"
ACCESS_KEY="${SWARMCLAW_ACCESS_KEY:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Check prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."

  # Check if SwarmClaw is running
  if ! curl -s "$SWARMCLAW_URL/api/auth" > /dev/null 2>&1; then
    log_error "SwarmClaw is not running at $SWARMCLAW_URL"
    log_info "Start SwarmClaw with: cd swarmclaw-app && npm run dev"
    exit 1
  fi

  # Check for access key
  if [ -z "$ACCESS_KEY" ]; then
    log_error "ACCESS_KEY not set"
    log_info "Set it with: export SWARMCLAW_ACCESS_KEY=your-key"
    log_info "Or find it in swarmclaw-app/.env.local"
    exit 1
  fi

  # Check for jq
  if ! command -v jq &> /dev/null; then
    log_warning "jq not found. Install with: brew install jq (macOS) or apt install jq (Linux)"
    log_info "Continuing without jq (less readable output)..."
  fi

  log_success "Prerequisites check passed"
}

# Create an agent via API
create_agent() {
  local agent_json="$1"
  local agent_name=$(echo "$agent_json" | jq -r '.name')

  log_info "Creating agent: $agent_name"

  response=$(curl -s -X POST "$SWARMCLAW_URL/api/agents" \
    -H "x-access-key: $ACCESS_KEY" \
    -H "Content-Type: application/json" \
    -d "$agent_json")

  if echo "$response" | jq -e '.ok' > /dev/null 2>&1; then
    agent_id=$(echo "$response" | jq -r '.agent.id')
    log_success "Created: $agent_name (ID: $agent_id)"
    echo "$agent_id"
  else
    log_error "Failed to create $agent_name"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
    echo ""
  fi
}

# Update orchestrator with sub-agent IDs
update_orchestrator_subagents() {
  local orchestrator_id="$1"
  shift
  local subagent_ids=("$@")

  log_info "Updating orchestrator with sub-agent IDs..."

  # Build JSON array of sub-agent IDs
  subagent_ids_json=$(printf '%s\n' "${subagent_ids[@]}" | jq -R . | jq -s .)

  response=$(curl -s -X PATCH "$SWARMCLAW_URL/api/agents/$orchestrator_id" \
    -H "x-access-key: $ACCESS_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"subAgentIds\": $subagent_ids_json}")

  if echo "$response" | jq -e '.ok' > /dev/null 2>&1; then
    log_success "Orchestrator updated with ${#subagent_ids[@]} sub-agents"
  else
    log_error "Failed to update orchestrator"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
  fi
}

# Setup technical swarm
setup_technical_swarm() {
  log_info "Setting up Technical Swarm..."

  local config_file="$PROJECT_ROOT/agent-configs/technical-swarm.json"
  if [ ! -f "$config_file" ]; then
    log_error "Configuration file not found: $config_file"
    return 1
  fi

  # Read agent configurations
  local agents=$(jq -c '.agents[]' "$config_file")

  local orchestrator_id=""
  local subagent_ids=()

  # Create each agent
  while IFS= read -r agent_json; do
    local is_orchestrator=$(echo "$agent_json" | jq -r '.isOrchestrator // false')
    local agent_id=$(create_agent "$agent_json")

    if [ -n "$agent_id" ]; then
      if [ "$is_orchestrator" = "true" ]; then
        orchestrator_id="$agent_id"
      else
        subagent_ids+=("$agent_id")
      fi
    fi
  done <<< "$agents"

  # Update orchestrator with sub-agent IDs
  if [ -n "$orchestrator_id" ] && [ ${#subagent_ids[@]} -gt 0 ]; then
    update_orchestrator_subagents "$orchestrator_id" "${subagent_ids[@]}"
  fi

  log_success "Technical Swarm setup complete"
  echo "$orchestrator_id" > "$PROJECT_ROOT/.tech-orchestrator-id"
}

# Setup business swarm
setup_business_swarm() {
  log_info "Setting up Business Swarm..."

  local config_file="$PROJECT_ROOT/agent-configs/business-swarm.json"
  if [ ! -f "$config_file" ]; then
    log_error "Configuration file not found: $config_file"
    return 1
  fi

  local agents=$(jq -c '.agents[]' "$config_file")

  local orchestrator_id=""
  local subagent_ids=()

  while IFS= read -r agent_json; do
    local is_orchestrator=$(echo "$agent_json" | jq -r '.isOrchestrator // false')
    local agent_id=$(create_agent "$agent_json")

    if [ -n "$agent_id" ]; then
      if [ "$is_orchestrator" = "true" ]; then
        orchestrator_id="$agent_id"
      else
        subagent_ids+=("$agent_id")
      fi
    fi
  done <<< "$agents"

  if [ -n "$orchestrator_id" ] && [ ${#subagent_ids[@]} -gt 0 ]; then
    update_orchestrator_subagents "$orchestrator_id" "${subagent_ids[@]}"
  fi

  log_success "Business Swarm setup complete"
  echo "$orchestrator_id" > "$PROJECT_ROOT/.business-orchestrator-id"
}

# Setup implementation agent
setup_implementation_agent() {
  log_info "Setting up Implementation Agent (Claude Code Pro)..."

  local config_file="$PROJECT_ROOT/agent-configs/implementation-agent.json"
  if [ ! -f "$config_file" ]; then
    log_error "Configuration file not found: $config_file"
    return 1
  fi

  local agent_json=$(jq -c '.agents[0]' "$config_file")
  local agent_id=$(create_agent "$agent_json")

  if [ -n "$agent_id" ]; then
    log_success "Implementation Agent setup complete"
    echo "$agent_id" > "$PROJECT_ROOT/.implementation-agent-id"
  fi
}

# Main execution
main() {
  echo ""
  log_info "SwarmClaw Multi-Agent Swarm Setup"
  echo ""

  check_prerequisites

  echo ""
  setup_technical_swarm

  echo ""
  setup_business_swarm

  echo ""
  setup_implementation_agent

  echo ""
  log_success "All swarms configured successfully!"
  echo ""
  log_info "Next steps:"
  echo "  1. Run technical analysis: ./scripts/run-technical-swarm.sh /path/to/your/repo"
  echo "  2. Run business analysis: ./scripts/run-business-swarm.sh /path/to/your/repo"
  echo "  3. Implement plans: ./scripts/run-implementation.sh"
  echo ""
}

main "$@"
