#!/bin/bash
# Example 1: Simple Repository Analysis (No Implementation)
# This example runs both swarms for analysis only

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
REPO_PATH="${1:-$PROJECT_ROOT}"

echo "Example 1: Simple Repository Analysis"
echo "======================================"
echo ""
echo "This will:"
echo "  1. Analyze your repository with technical experts"
echo "  2. Create business strategy recommendations"
echo "  3. Generate markdown reports"
echo "  4. Skip implementation (safe mode)"
echo ""

# Run full workflow without implementation
bash "$PROJECT_ROOT/scripts/run-full-workflow.sh" "$REPO_PATH" --skip-implementation

echo ""
echo "✓ Analysis complete!"
echo ""
echo "Review the outputs:"
echo "  - Technical: $REPO_PATH/technical-plan.md"
echo "  - Business: $REPO_PATH/business-strategy.md"
echo ""
