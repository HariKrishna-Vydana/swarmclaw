#!/bin/bash
# Example 3: Full Autonomous Workflow
# Complete end-to-end: analyze + implement

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

REPO_PATH="${1:-$PROJECT_ROOT}"

echo "Example 3: Full Autonomous Workflow"
echo "===================================="
echo ""
echo "⚠️  WARNING: This will make code changes!"
echo ""
echo "This example:"
echo "  1. Runs technical analysis"
echo "  2. Runs business analysis"
echo "  3. Waits for completion"
echo "  4. Implements changes autonomously"
echo ""
echo "Repository: $REPO_PATH"
echo ""

# Safety check
if [ ! -d "$REPO_PATH/.git" ]; then
  echo "❌ Error: Repository must be a git repo for safety"
  echo "   Initialize with: cd $REPO_PATH && git init"
  exit 1
fi

# Check for uncommitted changes
cd "$REPO_PATH"
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  echo "⚠️  You have uncommitted changes!"
  echo ""
  read -p "Create safety commit before proceeding? [Y/n] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    git add -A
    git commit -m "Safety commit before SwarmClaw autonomous workflow"
    echo "✓ Safety commit created"
    echo ""
  fi
fi

# Run full workflow
bash "$PROJECT_ROOT/scripts/run-full-workflow.sh" "$REPO_PATH"

echo ""
echo "✓ Full workflow complete!"
echo ""
echo "Review changes:"
echo "  cd $REPO_PATH"
echo "  git diff HEAD^"
echo "  git log"
echo ""
