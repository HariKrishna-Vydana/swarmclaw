# SwarmClaw Agent Swarms - Quick Start

Get your autonomous agent swarms running in 5 minutes.

## Prerequisites

1. **SwarmClaw running**:
   ```bash
   cd swarmclaw-app
   npm run dev
   ```

2. **Environment setup**:
   ```bash
   # Get your access key
   cat swarmclaw-app/.env.local | grep ACCESS_KEY

   # Export it
   export SWARMCLAW_ACCESS_KEY="your-access-key-here"
   ```

3. **Anthropic API key configured** in SwarmClaw UI (Providers section)

4. **Claude Code CLI** (for implementation):
   ```bash
   claude auth status  # Check if logged in
   ```

## 60-Second Setup

```bash
# 1. Setup all agents (one time)
./scripts/setup-swarms.sh

# 2. Analyze your repository
./scripts/run-full-workflow.sh /path/to/your/repo --skip-implementation

# 3. Wait for completion, then review
cat /path/to/your/repo/technical-plan.md
cat /path/to/your/repo/business-strategy.md
```

That's it! You now have comprehensive technical and business analysis.

## What Just Happened?

You created **13 AI agents**:

### Technical Team (6 agents)
- **Tech Lead** (orchestrator) - Coordinates the team
- **Architect** - System design analysis
- **Developer** - Implementation planning
- **Programmer** - Code quality review
- **Tester** - QA strategy
- **CTO** - Strategic decisions

### Business Team (6 agents)
- **Business Director** (orchestrator) - Coordinates the team
- **Product Manager** - Feature prioritization
- **Market Researcher** - Competitive analysis
- **Business Strategist** - Market positioning
- **Engineer-Business Liaison** - Technical feasibility
- **Growth Advisor** - Marketing strategy

### Implementation (1 agent)
- **Implementation Engineer** - Uses your Claude Code Pro subscription

## Examples

### Example 1: Just analyze (safe)
```bash
./examples/example-1-simple-analysis.sh /path/to/repo
```

### Example 2: Technical review only
```bash
./examples/example-2-technical-only.sh /path/to/repo
```

### Example 3: Full autonomous (with implementation)
```bash
./examples/example-3-full-autonomous.sh /path/to/repo
```

### Example 4: Analyze GitHub repo
```bash
./examples/example-4-github-clone.sh https://github.com/username/repo
```

## Monitoring

Watch your swarms in action:

```bash
# One-time status check
./scripts/monitor-swarms.sh

# Live monitoring (updates every 5s)
./scripts/monitor-swarms.sh --follow
```

Or open SwarmClaw UI:
```bash
open http://localhost:3456
```

## Outputs

After running, you'll find:

```
your-repo/
├── technical-plan.md        # Technical analysis & roadmap
├── business-strategy.md     # Business strategy & GTM plan
└── implementation-log.md    # Implementation details (if ran)
```

## Cost

- **Analysis only**: ~$0.60-$1.80 per run (Anthropic API)
- **Implementation**: Uses your Claude Code Pro subscription (unlimited)

## Next Steps

1. **Review the plans** - Edit them before implementation
2. **Run implementation** - Let Claude Code Pro implement the changes
3. **Iterate** - Re-run with updated context

## Cleanup

```bash
# Remove cached IDs only
./scripts/cleanup-swarms.sh

# Delete all agents and start fresh
./scripts/cleanup-swarms.sh --delete-agents --delete-tasks
```

## Need Help?

- **Full guide**: [SWARM-SETUP-GUIDE.md](./SWARM-SETUP-GUIDE.md)
- **SwarmClaw docs**: https://swarmclaw.ai/docs
- **Issues**: https://github.com/swarmclawai/swarmclaw/issues

---

**Pro tip**: Run the swarms on your current project right now. The insights are often surprising and immediately actionable! 🚀
