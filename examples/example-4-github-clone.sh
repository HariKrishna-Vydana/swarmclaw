#!/bin/bash
# Example 4: Analyze Remote GitHub Repository
# Clone a repo and analyze it

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

GITHUB_URL="${1:-}"

if [ -z "$GITHUB_URL" ]; then
  echo "Example 4: Analyze Remote GitHub Repository"
  echo "============================================"
  echo ""
  echo "Usage: $0 <github-url>"
  echo ""
  echo "Example:"
  echo "  $0 https://github.com/facebook/react"
  echo ""
  exit 1
fi

# Extract repo name
REPO_NAME=$(basename "$GITHUB_URL" .git)
CLONE_DIR="/tmp/swarmclaw-analysis-$REPO_NAME"

echo "Example 4: Analyze Remote GitHub Repository"
echo "============================================"
echo ""
echo "Repository: $GITHUB_URL"
echo "Clone to: $CLONE_DIR"
echo ""

# Clone repository
if [ -d "$CLONE_DIR" ]; then
  echo "Directory exists, pulling latest..."
  cd "$CLONE_DIR"
  git pull
else
  echo "Cloning repository..."
  git clone "$GITHUB_URL" "$CLONE_DIR"
fi

echo ""
echo "✓ Repository ready"
echo ""

# Run analysis
bash "$PROJECT_ROOT/scripts/run-full-workflow.sh" "$CLONE_DIR" --skip-implementation

echo ""
echo "✓ Analysis complete!"
echo ""
echo "Results saved to:"
echo "  $CLONE_DIR/technical-plan.md"
echo "  $CLONE_DIR/business-strategy.md"
echo ""
