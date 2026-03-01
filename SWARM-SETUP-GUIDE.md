# SwarmClaw Multi-Agent Orchestration Setup Guide

This guide will help you set up autonomous agent swarms to analyze your GitHub repository, discuss technical and business strategies, and implement improvements using your Claude Code Pro subscription.

## Overview

You'll create **three autonomous systems**:

1. **Technical Swarm** - 6 agents (Orchestrator + 5 specialists)
   - Tech Lead (Orchestrator)
   - Architect
   - Developer
   - Programmer
   - Tester
   - CTO

2. **Business Swarm** - 6 agents (Orchestrator + 5 specialists)
   - Business Director (Orchestrator)
   - Product Manager
   - Market Researcher
   - Business Strategist
   - Engineer-Business Liaison
   - Growth Advisor

3. **Implementation Agent** - 1 agent (Claude Code Pro)
   - Full autonomous implementation
   - Shell, file, git, and browser access
   - Reads plans and implements changes

## Architecture

```
┌─────────────────────────────────────────┐
│  1. TECHNICAL SWARM                     │
│  ├─ Reads your repo                     │
│  ├─ Agents discuss architecture         │
│  ├─ Breaks down tasks                   │
│  └─ Outputs: technical-plan.md          │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  2. BUSINESS SWARM                      │
│  ├─ Reads your repo                     │
│  ├─ Agents discuss market strategy      │
│  ├─ Prioritizes features                │
│  └─ Outputs: business-strategy.md       │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  3. IMPLEMENTATION AGENT                │
│  ├─ Reads both plan files               │
│  ├─ Implements features autonomously    │
│  ├─ Runs tests                          │
│  └─ Outputs: implementation-log.md      │
└─────────────────────────────────────────┘
```

## Prerequisites

### 1. SwarmClaw Running

```bash
cd swarmclaw-app
npm run dev
# SwarmClaw should be running at http://localhost:3456
```

### 2. Environment Setup

```bash
# Get your access key from .env.local
cat swarmclaw-app/.env.local | grep ACCESS_KEY

# Export it for scripts
export SWARMCLAW_ACCESS_KEY="your-access-key-here"
```

### 3. Claude Code Pro (for implementation agent)

Ensure you have Claude Code CLI installed and authenticated:

```bash
# Install Claude Code CLI if not already installed
# See: https://docs.anthropic.com/en/docs/claude-code/overview

# Check authentication
claude auth status

# Login if needed
claude auth login
```

### 4. API Provider Configuration

In SwarmClaw UI, ensure you have an **Anthropic API key** configured:

1. Go to SwarmClaw UI → Providers
2. Add Anthropic provider
3. Enter your Anthropic API key
4. Save

All orchestrator agents use `claude-sonnet-4-20250514` via API, while the implementation agent uses your Claude Code Pro subscription via CLI.

### 5. Install jq (for scripts)

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Or continue without it (output will be less readable)
```

## Step-by-Step Setup

### Step 1: Create All Agents

Run the setup script to create all 13 agents:

```bash
./scripts/setup-swarms.sh
```

This will:
- Create 6 technical team agents (1 orchestrator + 5 specialists)
- Create 6 business team agents (1 orchestrator + 5 specialists)
- Create 1 implementation agent (Claude Code Pro)
- Configure orchestrator sub-agent relationships
- Save orchestrator IDs to hidden files for automation

**Expected output:**
```
ℹ SwarmClaw Multi-Agent Swarm Setup

ℹ Checking prerequisites...
✓ Prerequisites check passed

ℹ Setting up Technical Swarm...
ℹ Creating agent: Tech Lead (Orchestrator)
✓ Created: Tech Lead (Orchestrator) (ID: ag_xxx)
ℹ Creating agent: Architect
✓ Created: Architect (ID: ag_yyy)
...
✓ Technical Swarm setup complete

ℹ Setting up Business Swarm...
...
✓ Business Swarm setup complete

ℹ Setting up Implementation Agent (Claude Code Pro)...
✓ Implementation Agent setup complete

✓ All swarms configured successfully!
```

### Step 2: Run Technical Analysis

Point the technical swarm at your repository:

```bash
# Local repository
./scripts/run-technical-swarm.sh /path/to/your/repo

# Or with GitHub URL (agents will clone it)
./scripts/run-technical-swarm.sh /tmp/analysis https://github.com/yourusername/yourrepo
```

**What happens:**
1. Tech Lead orchestrator receives the task
2. Delegates to each specialist:
   - **Architect** analyzes system design
   - **Developer** reviews implementation
   - **Programmer** checks code quality
   - **Tester** assesses test coverage
   - **CTO** provides strategic guidance
3. Synthesizes all feedback
4. Writes comprehensive plan to `technical-plan.md`

**Expected output:**
```
ℹ Starting Technical Swarm Analysis...
ℹ Orchestrator ID: ag_xxx
✓ Technical analysis started!
ℹ Task ID: task_xxx

ℹ Monitor progress in SwarmClaw UI at: http://localhost:3456
ℹ Output will be written to: technical-plan.md
```

**Monitor progress:**
- Open SwarmClaw UI
- Go to Tasks tab
- Watch the orchestrator delegate to each agent
- See results in session messages

### Step 3: Run Business Analysis

Run the business swarm (can run in parallel with technical):

```bash
./scripts/run-business-swarm.sh /path/to/your/repo
```

**What happens:**
1. Business Director orchestrator receives the task
2. Delegates to specialists:
   - **Product Manager** prioritizes features
   - **Market Researcher** analyzes competition
   - **Business Strategist** defines positioning
   - **Engineer-Business Liaison** assesses feasibility
   - **Growth Advisor** plans marketing
3. Performs web research on competitors
4. Synthesizes business strategy
5. Writes plan to `business-strategy.md`

**Output structure:**
- Executive Summary
- Product Vision & Positioning
- Competitive Landscape
- Target Market
- Feature Roadmap (MVP focus)
- Go-to-Market Strategy
- Revenue Model
- Growth Plan
- KPIs
- Resource Requirements

### Step 4: Review the Plans

Before implementation, review both plans:

```bash
# Technical plan
cat technical-plan.md

# Business plan
cat business-strategy.md
```

**Edit if needed** - these are markdown files you can adjust manually before implementation.

### Step 5: Run Implementation

Once you're satisfied with the plans, trigger the implementation agent:

```bash
./scripts/run-implementation.sh /path/to/your/repo
```

**What happens:**
1. Implementation Agent (Claude Code Pro) reads both plans
2. Understands current codebase
3. Implements changes autonomously:
   - Follows task breakdown
   - Writes code
   - Adds tests
   - Runs validation
4. Creates `implementation-log.md` with details

**This agent has full access:**
- Shell commands
- File operations
- Git operations
- Web browsing
- All Claude Code Pro capabilities

**Monitor carefully** in the SwarmClaw UI to ensure safe operations.

## Advanced Usage

### Running Individual Agents

You can also trigger agents manually via SwarmClaw UI:

1. Go to Sessions → New Session
2. Select the orchestrator agent
3. Enter your task description
4. Watch the multi-agent discussion unfold

### Customizing Agent Prompts

Edit agent configurations in `agent-configs/*.json`:

```bash
# Edit technical team
vim agent-configs/technical-swarm.json

# Edit business team
vim agent-configs/business-swarm.json

# Edit implementation agent
vim agent-configs/implementation-agent.json
```

Then re-run `./scripts/setup-swarms.sh` to update agents.

### Custom Workflows

Create your own orchestration tasks by calling the API directly:

```bash
ORCHESTRATOR_ID="ag_your_tech_lead_id"
ACCESS_KEY="your-access-key"

curl -X POST "http://localhost:3456/api/orchestrator/run" \
  -H "x-access-key: $ACCESS_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "agentId": "'"$ORCHESTRATOR_ID"'",
    "task": "Analyze our authentication system and suggest improvements"
  }'
```

### Scheduled Analysis

Use SwarmClaw's scheduler to run weekly analysis:

1. Go to Schedules in SwarmClaw UI
2. Create new schedule
3. Select orchestrator agent
4. Set cron: `0 9 * * 1` (every Monday 9am)
5. Task: "Weekly codebase review and improvement suggestions"

## Output Files

After running all swarms, you'll have:

```
your-repo/
├── technical-plan.md           # Technical analysis & roadmap
├── business-strategy.md        # Business strategy & GTM plan
└── implementation-log.md       # Implementation details & changes
```

## Troubleshooting

### Issue: "Orchestrator ID not found"

**Solution:**
```bash
# Re-run setup
./scripts/setup-swarms.sh

# Or manually set IDs
echo "ag_your_id" > .tech-orchestrator-id
echo "ag_your_id" > .business-orchestrator-id
echo "ag_your_id" > .implementation-agent-id
```

### Issue: "SwarmClaw is not running"

**Solution:**
```bash
cd swarmclaw-app
npm run dev
```

### Issue: Claude Code CLI not found

**Solution:**
```bash
# Install Claude Code CLI
# See: https://docs.anthropic.com/en/docs/claude-code/overview

# Authenticate
claude auth login
```

### Issue: Anthropic API errors

**Solution:**
- Check API key in SwarmClaw UI → Providers
- Ensure you have API credits
- Check rate limits

### Issue: Implementation agent makes unwanted changes

**Solution:**
- Review plans before implementation
- Monitor the session in real-time
- Use git to review/revert changes
- Adjust agent's system prompt to be more conservative

## Cost Considerations

### API Usage (Anthropic)

Each orchestrator run uses approximately:
- **Technical Swarm**: ~100K-300K tokens (~$0.30-$0.90 with Sonnet)
- **Business Swarm**: ~100K-300K tokens (~$0.30-$0.90 with Sonnet)

Total per full analysis: **~$0.60-$1.80**

### Claude Code Pro

Implementation uses your **Claude Code Pro subscription** (unlimited messages), so there's no additional API cost for implementation.

## Best Practices

### 1. Incremental Approach

Start small:
```bash
# First run: Just analyze
./scripts/run-technical-swarm.sh /path/to/small-module

# Review output
cat technical-plan.md

# If good, scale up to full repo
```

### 2. Version Control

Always commit before implementation:
```bash
cd /path/to/your/repo
git commit -am "Pre-swarm checkpoint"
./scripts/run-implementation.sh .
```

### 3. Supervision

Monitor implementation in real-time:
- Keep SwarmClaw UI open
- Watch session messages
- Intervene if needed (stop session)

### 4. Iterative Refinement

Use the plans as living documents:
```bash
# Run initial analysis
./scripts/run-technical-swarm.sh /path/to/repo

# Edit technical-plan.md with your insights

# Run business analysis with context
./scripts/run-business-swarm.sh /path/to/repo

# Edit business-strategy.md

# Implement refined plans
./scripts/run-implementation.sh /path/to/repo
```

## Example Workflow for a New Product

```bash
# 1. Initial setup (one time)
export SWARMCLAW_ACCESS_KEY="your-key"
./scripts/setup-swarms.sh

# 2. Clone your repo
git clone https://github.com/yourusername/yourproduct.git
cd yourproduct

# 3. Run both swarms in parallel
(cd .. && ./scripts/run-technical-swarm.sh ./yourproduct) &
(cd .. && ./scripts/run-business-swarm.sh ./yourproduct) &
wait

# 4. Review plans (wait for completion)
echo "Waiting for swarms to complete..."
sleep 300  # Adjust based on repo size

# 5. Review outputs
cat technical-plan.md
cat business-strategy.md

# 6. Optional: Edit plans manually
vim technical-plan.md
vim business-strategy.md

# 7. Commit plans to repo
git add technical-plan.md business-strategy.md
git commit -m "Add swarm analysis and strategy"

# 8. Run implementation (supervised)
cd .. && ./scripts/run-implementation.sh ./yourproduct

# 9. Review changes
cd yourproduct
git diff
git log

# 10. Test and iterate
npm test  # or your test command
```

## Next Steps

### Extend the System

1. **Add more specialists**: Create agents for security, performance, UX, etc.
2. **Custom skills**: Add SwarmClaw skills for domain-specific tasks
3. **Webhooks**: Trigger analysis on git push via SwarmClaw webhooks
4. **Scheduled reviews**: Set up weekly/monthly automated reviews
5. **Multi-repo orchestration**: Analyze multiple repos and suggest integration improvements

### Integration Ideas

- **CI/CD**: Run swarms on PR creation
- **Slack notifications**: Get swarm results in Slack
- **Dashboard**: Build custom UI to visualize swarm outputs
- **Memory**: Use SwarmClaw's memory system to track decisions over time

## Support

- **SwarmClaw Docs**: https://swarmclaw.ai/docs
- **GitHub Issues**: https://github.com/swarmclawai/swarmclaw/issues
- **Agent Configs**: `agent-configs/*.json`
- **Scripts**: `scripts/*.sh`

---

## Quick Reference

```bash
# Setup (once)
export SWARMCLAW_ACCESS_KEY="your-key"
./scripts/setup-swarms.sh

# Analyze (per repo)
./scripts/run-technical-swarm.sh /path/to/repo
./scripts/run-business-swarm.sh /path/to/repo

# Implement
./scripts/run-implementation.sh /path/to/repo

# Monitor
open http://localhost:3456  # SwarmClaw UI

# Review
cat technical-plan.md
cat business-strategy.md
cat implementation-log.md
```

Good luck with your autonomous agent swarms! 🚀
