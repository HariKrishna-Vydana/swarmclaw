#!/bin/bash
# Example 2: Technical Analysis Only
# Run just the technical swarm for code review

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

REPO_PATH="${1:-$PROJECT_ROOT}"

echo "Example 2: Technical Analysis Only"
echo "==================================="
echo ""
echo "Running technical swarm for code review and architecture analysis..."
echo ""

bash "$PROJECT_ROOT/scripts/run-technical-swarm.sh" "$REPO_PATH"

echo ""
echo "Technical analysis started!"
echo "Monitor at: http://localhost:3456"
echo ""
echo "To monitor progress:"
echo "  ./scripts/monitor-swarms.sh --follow"
echo ""
