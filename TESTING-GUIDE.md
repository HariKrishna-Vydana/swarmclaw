# Multi-Agent Swarm System - Testing Guide

This guide walks through testing the complete multi-agent orchestration system on SwarmClaw itself (meta-testing!).

## Prerequisites

### 1. Install Dependencies & Setup SwarmClaw

```bash
# Install dependencies
npm install

# Run easy setup (creates .env.local, data/, etc.)
npm run setup:easy

# Start SwarmClaw
npm run dev
# Should see: "Server running on http://0.0.0.0:3456"
```

### 2. Get Your Access Key

```bash
# Access key is auto-generated in .env.local
cat .env.local | grep ACCESS_KEY

# Export it for the scripts
export SWARMCLAW_ACCESS_KEY="$(grep ACCESS_KEY .env.local | cut -d'=' -f2)"
```

### 3. Configure Anthropic API Key

1. Open http://localhost:3456
2. Login with your access key
3. Go to Providers → Add Anthropic
4. Enter your Anthropic API key
5. Save

### 4. (Optional) Authenticate Claude Code CLI

For the implementation agent:

```bash
# Check if authenticated
claude auth status

# Login if needed
claude auth login
```

## Test Plan

### Phase 1: Setup Test (5 minutes)

Create all 13 agents via the setup script:

```bash
# Set access key
export SWARMCLAW_ACCESS_KEY="$(grep ACCESS_KEY .env.local | cut -d'=' -f2)"

# Run setup
./scripts/setup-swarms.sh
```

**Expected Output:**
```
✓ Prerequisites check passed
ℹ Setting up Technical Swarm...
✓ Created: Tech Lead (Orchestrator) (ID: ag_xxx)
✓ Created: Architect (ID: ag_xxx)
✓ Created: Developer (ID: ag_xxx)
✓ Created: Programmer (ID: ag_xxx)
✓ Created: Tester (ID: ag_xxx)
✓ Created: CTO (ID: ag_xxx)
✓ Technical Swarm setup complete

ℹ Setting up Business Swarm...
✓ Created: Business Director (Orchestrator) (ID: ag_xxx)
✓ Created: Product Manager (ID: ag_xxx)
✓ Created: Market Researcher (ID: ag_xxx)
✓ Created: Business Strategist (ID: ag_xxx)
✓ Created: Engineer-Business Liaison (ID: ag_xxx)
✓ Created: Growth Advisor (ID: ag_xxx)
✓ Business Swarm setup complete

ℹ Setting up Implementation Agent (Claude Code Pro)...
✓ Created: Implementation Engineer (ID: ag_xxx)
✓ Implementation Agent setup complete

✓ All swarms configured successfully!
```

**Verification:**
- Open http://localhost:3456
- Go to Agents tab
- Verify all 13 agents are created
- Check that Tech Lead and Business Director show `isOrchestrator: true`
- Verify they have `subAgentIds` configured

### Phase 2: Technical Swarm Test (10-15 minutes)

Test the technical swarm by analyzing SwarmClaw itself:

```bash
# Run technical analysis on SwarmClaw repo
./scripts/run-technical-swarm.sh /Users/harivydana/swarmclaw
```

**Monitor Progress:**

Option 1: Live monitoring
```bash
# In another terminal
./scripts/monitor-swarms.sh --follow
```

Option 2: SwarmClaw UI
- Open http://localhost:3456
- Go to Tasks tab
- Click on the running task
- Watch the multi-agent discussion unfold

**Expected Behavior:**
1. Tech Lead orchestrator creates a session
2. Reads the SwarmClaw codebase
3. Delegates tasks to each specialist:
   - Architect analyzes the architecture
   - Developer reviews implementation
   - Programmer checks code quality
   - Tester assesses test coverage
   - CTO provides strategic guidance
4. Synthesizes all insights
5. Writes `technical-plan.md` to the repository

**Verification:**
```bash
# Check if plan was created
test -f technical-plan.md && echo "✓ Technical plan created" || echo "✗ Plan not found"

# View the plan
cat technical-plan.md

# Check plan structure
grep -E "^#+ " technical-plan.md
```

Expected sections:
- Executive Summary
- System Architecture Analysis
- Task Breakdown
- Implementation Roadmap
- Testing Strategy
- Technical Debt & Improvements
- Risk Assessment

### Phase 3: Business Swarm Test (10-15 minutes)

Test the business swarm:

```bash
# Run business analysis
./scripts/run-business-swarm.sh /Users/harivydana/swarmclaw
```

**Expected Behavior:**
1. Business Director orchestrator creates a session
2. Reads the codebase to understand capabilities
3. Delegates tasks:
   - Product Manager prioritizes features
   - Market Researcher analyzes competition (uses web_search)
   - Business Strategist defines positioning
   - Engineer-Business Liaison assesses feasibility
   - Growth Advisor creates marketing strategy
4. Synthesizes business strategy
5. Writes `business-strategy.md`

**Verification:**
```bash
# Check if strategy was created
test -f business-strategy.md && echo "✓ Business strategy created" || echo "✗ Strategy not found"

# View the strategy
cat business-strategy.md

# Check structure
grep -E "^#+ " business-strategy.md
```

Expected sections:
- Executive Summary
- Product Vision & Positioning
- Competitive Landscape Analysis
- Target Market & Customer Segments
- Feature Roadmap & Prioritization
- Go-to-Market Strategy
- Revenue Model
- Growth & Marketing Plan
- Success Metrics & KPIs

### Phase 4: Full Workflow Test (20-30 minutes)

Test the complete end-to-end workflow:

```bash
# Run both swarms in parallel
./scripts/run-full-workflow.sh /Users/harivydana/swarmclaw --skip-implementation
```

**Expected Behavior:**
1. Triggers both technical and business swarms in parallel
2. Waits for both to complete
3. Reports status
4. Skips implementation (safe mode)

**Verification:**
```bash
# Both plans should exist
ls -lh technical-plan.md business-strategy.md

# Count total lines
wc -l technical-plan.md business-strategy.md
```

### Phase 5: Implementation Test (Optional, 15-30 minutes)

⚠️ **WARNING: This will make code changes!**

Only run this if:
- You have committed all changes: `git commit -am "Pre-test checkpoint"`
- You're comfortable reviewing and potentially reverting changes
- Claude Code CLI is authenticated

```bash
# Create safety checkpoint
git commit -am "Safety checkpoint before implementation test"

# Run implementation
./scripts/run-implementation.sh /Users/harivydana/swarmclaw
```

**Expected Behavior:**
1. Implementation Engineer reads `technical-plan.md` and `business-strategy.md`
2. Analyzes current codebase
3. Implements high-priority items from the plans
4. Runs tests (if available)
5. Creates `implementation-log.md`

**Verification:**
```bash
# Check implementation log
cat implementation-log.md

# Review code changes
git diff

# Check what files changed
git status

# Run tests (if you have them)
npm test
```

**If you want to revert:**
```bash
git reset --hard HEAD
```

### Phase 6: Example Workflows Test

Test each example script:

#### Example 1: Simple Analysis
```bash
./examples/example-1-simple-analysis.sh /Users/harivydana/swarmclaw
```

#### Example 2: Technical Only
```bash
./examples/example-2-technical-only.sh /Users/harivydana/swarmclaw
```

#### Example 3: Full Autonomous (⚠️ makes changes)
```bash
# Commit first!
git commit -am "Pre-example-3 checkpoint"

./examples/example-3-full-autonomous.sh /Users/harivydana/swarmclaw
```

#### Example 4: GitHub Repo Analysis
```bash
# Test on a public repo (e.g., a small sample project)
./examples/example-4-github-clone.sh https://github.com/vercel/next.js
```

## Validation Checklist

After testing, verify:

- [ ] All 13 agents created successfully
- [ ] Technical swarm completes without errors
- [ ] Business swarm completes without errors
- [ ] `technical-plan.md` is comprehensive and actionable
- [ ] `business-strategy.md` is detailed with market insights
- [ ] Monitoring script shows correct status
- [ ] Implementation agent (if tested) makes sensible changes
- [ ] All example scripts work correctly
- [ ] Documentation is clear and accurate

## Performance Metrics

Track these during testing:

| Metric | Expected | Actual |
|--------|----------|--------|
| Setup time | 2-5 min | _____ |
| Technical swarm time | 10-15 min | _____ |
| Business swarm time | 10-15 min | _____ |
| Implementation time | 15-30 min | _____ |
| API cost (technical) | $0.30-$0.90 | _____ |
| API cost (business) | $0.30-$0.90 | _____ |
| Technical plan lines | 200-500 | _____ |
| Business plan lines | 200-500 | _____ |

## Known Issues & Troubleshooting

### Issue: Setup script fails with API errors

**Cause:** Anthropic API key not configured or invalid

**Solution:**
1. Check API key in SwarmClaw UI → Providers
2. Verify you have API credits
3. Check for rate limits

### Issue: Swarms timeout or fail

**Cause:** Large repository, network issues, or API limits

**Solution:**
1. Try a smaller test repository first
2. Check network connectivity
3. Increase timeout in scripts if needed

### Issue: Plans are incomplete

**Cause:** Agent ran out of context or hit recursion limit

**Solution:**
1. Check Settings → Runtime & Loop Controls
2. Increase `orchestratorLoopRecursionLimit` if needed
3. Review session messages for errors

### Issue: Implementation makes unexpected changes

**Cause:** Plans may be ambiguous or agent misinterpreted requirements

**Solution:**
1. Review plans carefully before implementation
2. Use `--skip-implementation` first
3. Edit plans manually to clarify requirements
4. Monitor implementation in real-time via UI

## Test Results Template

Copy this template to document your test results:

```markdown
# Multi-Agent Swarm Test Results

**Date:** YYYY-MM-DD
**Tester:** [Your Name]
**SwarmClaw Version:** [Git commit hash]

## Setup
- [ ] Dependencies installed
- [ ] SwarmClaw running
- [ ] Anthropic API configured
- [ ] Claude Code CLI authenticated
- [ ] All scripts executable

## Phase 1: Setup
- Agents created: ___/13
- Errors: [None / List errors]
- Time: ___ minutes

## Phase 2: Technical Swarm
- Status: [Success / Failed]
- Plan created: [Yes / No]
- Plan quality: [Excellent / Good / Fair / Poor]
- Time: ___ minutes
- Cost: $___
- Issues: [None / List issues]

## Phase 3: Business Swarm
- Status: [Success / Failed]
- Strategy created: [Yes / No]
- Strategy quality: [Excellent / Good / Fair / Poor]
- Time: ___ minutes
- Cost: $___
- Issues: [None / List issues]

## Phase 4: Full Workflow
- Status: [Success / Failed]
- Both plans created: [Yes / No]
- Time: ___ minutes
- Total cost: $___
- Issues: [None / List issues]

## Phase 5: Implementation (if tested)
- Status: [Success / Failed / Skipped]
- Changes made: [Yes / No]
- Changes quality: [Excellent / Good / Fair / Poor]
- Tests passing: [Yes / No / N/A]
- Time: ___ minutes
- Issues: [None / List issues]

## Overall Assessment
- System readiness: [Production / Beta / Alpha / Needs work]
- Documentation quality: [Excellent / Good / Fair / Poor]
- Ease of use: [Very easy / Easy / Moderate / Difficult]
- Recommended improvements: [List]

## Sample Outputs
[Attach or link to generated technical-plan.md and business-strategy.md]
```

## Next Steps After Testing

1. **If tests pass:**
   - Document test results
   - Create PR from `feature/multi-agent-swarms` branch
   - Share sample outputs (technical-plan.md, business-strategy.md)
   - Merge to main

2. **If issues found:**
   - Document issues in test results
   - Fix identified problems
   - Re-test
   - Update documentation if needed

3. **Improvements to consider:**
   - Add more specialized agents (Security, Performance, UX)
   - Create industry-specific swarm templates
   - Add visualization of agent discussions
   - Create CI/CD integration examples

## Test Completion

When testing is complete, you should have:
- ✅ Verified all 13 agents work correctly
- ✅ Confirmed multi-agent orchestration functions
- ✅ Validated output quality and usefulness
- ✅ Documented any issues or improvements
- ✅ Sample outputs for demonstration

Ready to merge! 🚀
