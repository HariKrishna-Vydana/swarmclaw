# SwarmClaw Agent Terminal Control via Claude Code

**How to give an AI agent full terminal control to write code and commit through Claude Code CLI, orchestrated by SwarmClaw.**

> Completed: March 12, 2026 — commit `efad3fc` by `OpenClaw <openclaw@swarmclaw.local>`

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Step-by-Step Setup](#step-by-step-setup)
5. [Sending a Coding Task](#sending-a-coding-task)
6. [What Happens Under the Hood](#what-happens-under-the-hood)
7. [Verifying the Result](#verifying-the-result)
8. [Alternative Approaches](#alternative-approaches)
9. [Security Considerations](#security-considerations)
10. [Reference: API Endpoints Used](#reference-api-endpoints-used)
11. [Appendix: Full Output Trace](#appendix-full-output-trace)

---

## Overview

SwarmClaw is a self-hosted AI agent orchestration dashboard. One of its core capabilities is spawning **Claude Code CLI** as a child process, giving an agent full terminal control — file creation, shell execution, git operations — all autonomously.

This tutorial walks through the exact steps to:

- Create a coding agent in SwarmClaw
- Point it at a project directory
- Send it a task ("write 5 Fibonacci variants and commit")
- Have Claude Code take over the terminal, write the code, test it, and commit with a custom author

The entire flow is **3 API calls** and takes about 60 seconds.

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│  YOU (curl / browser / Telegram / Discord / Slack)       │
└────────────────────────┬─────────────────────────────────┘
                         │ HTTP POST with task message
                         ▼
┌──────────────────────────────────────────────────────────┐
│  SWARMCLAW  (Next.js on localhost:3456)                   │
│                                                          │
│  ┌─────────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │ Agent Store  │   │ Session Mgr  │   │ Run Manager  │  │
│  │ (SQLite)     │   │              │   │ (Queue)      │  │
│  └──────┬──────┘   └──────┬───────┘   └──────┬───────┘  │
│         │                 │                   │          │
│         └────────┬────────┘                   │          │
│                  ▼                            │          │
│  ┌───────────────────────────────────────┐    │          │
│  │ Provider: claude-cli                  │◄───┘          │
│  │                                       │               │
│  │  spawn("claude", [                    │               │
│  │    "--print",                         │               │
│  │    "--output-format", "stream-json",  │               │
│  │    "--verbose",                       │               │
│  │    "--dangerously-skip-permissions"   │               │
│  │  ])                                   │               │
│  └───────────────┬───────────────────────┘               │
│                  │ stdin: task description                │
│                  │ stdout: NDJSON events                  │
│                  │ cwd: /your/project                     │
└──────────────────┼───────────────────────────────────────┘
                   ▼
┌──────────────────────────────────────────────────────────┐
│  CLAUDE CODE CLI  (child process)                        │
│                                                          │
│  Has full access to:                                     │
│  • File system (read/write/create)                       │
│  • Shell commands (python3, git, npm, etc.)              │
│  • Project context (understands repo structure)          │
│  • Session persistence (resumable via --resume)          │
└──────────────────────────────────────────────────────────┘
```

**Key files in SwarmClaw that make this work:**

| File | Role |
|------|------|
| `src/lib/providers/claude-cli.ts` | Spawns `claude` binary, streams NDJSON, manages session IDs |
| `src/lib/server/session-tools/delegate.ts` | `delegate_to_claude_code` tool (for non-CLI providers) |
| `src/lib/server/process-manager.ts` | Manages long-running child processes |
| `src/app/api/agents/route.ts` | Agent CRUD |
| `src/app/api/sessions/route.ts` | Session CRUD |
| `src/app/api/sessions/[id]/chat/route.ts` | SSE chat endpoint that triggers runs |

---

## Prerequisites

### 1. Claude Code CLI (installed + authenticated)

```bash
# Check if installed
which claude
# Expected: /home/<user>/.local/bin/claude  (or similar)

# Check version
claude --version
# Expected: 2.x.x (Claude Code)

# Check authentication
claude auth status
# Expected: {"loggedIn": true, ...}
```

If not installed, see [Claude Code docs](https://docs.anthropic.com/en/docs/claude-code). If not authenticated:

```bash
claude auth login
# or for API key auth:
claude setup-token
```

**Requirement:** Claude Code Pro subscription (for unlimited usage) or Anthropic API key.

### 2. SwarmClaw running

```bash
cd swarmclaw-app   # or wherever your swarmclaw lives
npm install
npm run dev        # starts on 0.0.0.0:3456
```

### 3. Access key

SwarmClaw auto-generates an access key on first run. Find it in `.env.local`:

```bash
grep ACCESS_KEY .env.local
# Example: ACCESS_KEY=3349279647d12e526141efbb97108952
```

Save this — you'll need it for every API call.

### 4. A git repository to work in

Any local git repo. The agent will create files and commit within this directory.

```bash
# Verify your target repo
cd /path/to/your/project
git status
```

---

## Step-by-Step Setup

### Step 1: Create a Coding Agent

```bash
SC_KEY="YOUR_ACCESS_KEY_HERE"

curl -s -X POST \
  -H "X-Access-Key: $SC_KEY" \
  -H "Content-Type: application/json" \
  http://localhost:3456/api/agents \
  -d '{
    "name": "OpenClaw Coder",
    "description": "Autonomous coding agent with terminal control via Claude Code",
    "provider": "claude-cli",
    "model": "",
    "tools": ["shell", "files", "edit_file", "process"],
    "systemPrompt": "You are OpenClaw Coder, an autonomous coding agent. You write clean, well-structured code. When asked to commit, use git with author \"OpenClaw <openclaw@swarmclaw.local>\". Always complete the full task before responding."
  }'
```

**What this does:**
- Creates an agent named "OpenClaw Coder"
- Sets `provider: "claude-cli"` — every message goes through the `claude` binary
- Enables `shell`, `files`, `edit_file`, `process` tools
- Sets a system prompt that instructs the agent to use the OpenClaw git author

**Save the returned `id`** (e.g., `"id": "20b62591"`). You'll need it next.

### Step 2: Create a Session

```bash
AGENT_ID="20b62591"   # from Step 1

curl -s -X POST \
  -H "X-Access-Key: $SC_KEY" \
  -H "Content-Type: application/json" \
  http://localhost:3456/api/sessions \
  -d '{
    "name": "Fibonacci Coding Task",
    "agentId": "'$AGENT_ID'",
    "cwd": "/path/to/your/project",
    "provider": "claude-cli",
    "tools": ["shell", "files", "edit_file", "process"]
  }'
```

**What this does:**
- Creates a session linked to the agent
- Sets the **working directory** (`cwd`) — Claude Code will operate here
- The session is persistent: you can send multiple messages to it

**Save the returned `id`** (e.g., `"id": "476c7e52"`).

### Step 3: Send the Coding Task

```bash
SESSION_ID="476c7e52"   # from Step 2

curl -N -X POST \
  -H "X-Access-Key: $SC_KEY" \
  -H "Content-Type: application/json" \
  "http://localhost:3456/api/sessions/$SESSION_ID/chat" \
  -d '{
    "message": "Create a file called fibonacci_variants.py with 5 Fibonacci implementations:\n1. Recursive (naive)\n2. Memoized (lru_cache)\n3. Iterative (loop)\n4. Generator (yield)\n5. Matrix Exponentiation (O(log n))\n\nEach should have a docstring. Add a __main__ block that tests all 5 with n=10.\n\nRun the file with python3 to verify. Then commit:\n  git add fibonacci_variants.py\n  git commit --author=\"OpenClaw <openclaw@swarmclaw.local>\" -m \"feat: add 5 Fibonacci variants - openclaw commit\"\n\nDo NOT push."
  }'
```

**What happens now:**
1. SwarmClaw queues the run
2. The `claude-cli` provider spawns `claude --print --output-format stream-json --verbose --dangerously-skip-permissions`
3. The task is written to Claude Code's stdin
4. Claude Code takes terminal control: creates the file, runs it, commits it
5. NDJSON events stream back via SSE (Server-Sent Events)
6. You see `{"t":"done"}` when complete

The `-N` flag on curl disables buffering so you see events in real time.

---

## What Happens Under the Hood

### The spawn chain (traced from source)

```
POST /api/sessions/{id}/chat
  → src/app/api/sessions/[id]/chat/route.ts
    → enqueueSessionRun()
      → src/lib/server/session-run-manager.ts
        → executeChatRun()
          → src/lib/server/chat-execution.ts
            → detects provider === "claude-cli"
              → streamClaudeCliChat()
                → src/lib/providers/claude-cli.ts
                  → spawn("claude", args, { cwd: session.cwd })
                    → CLAUDE CODE CLI TAKES OVER
```

### Claude Code CLI arguments

```
claude \
  --print \                              # non-interactive, print output
  --output-format stream-json \          # NDJSON events on stdout
  --verbose \                            # include tool_use/tool_result events
  --dangerously-skip-permissions \       # no permission prompts (autonomous)
  --resume <session_id>                  # (on subsequent messages)
```

### NDJSON event types streamed back

| Event type | Meaning |
|-----------|---------|
| `{"type": "system", "session_id": "..."}` | Session started, ID captured |
| `{"type": "assistant", "message": {"content": [...]}}` | Claude's text response |
| `{"type": "content_block_delta", "delta": {"text": "..."}}` | Streaming text chunk |
| `{"type": "result", "result": "..."}` | Final result text |

SwarmClaw parses these and re-emits them as SSE events (`{"t":"md", "text":"..."}`, `{"t":"r", "text":"..."}`, `{"t":"done"}`).

### Session persistence

After the first message, Claude Code returns a `session_id`. SwarmClaw stores it in `session.claudeSessionId`. Subsequent messages to the same session use `--resume <id>`, so Claude Code retains full context of previous work.

---

## Verifying the Result

### Check the git log

```bash
git log -1 --format="Commit: %H%nAuthor: %an <%ae>%nDate:   %ad%nMessage: %s"
```

Expected:

```
Commit: efad3fc9ec644071b429622cb2970451356baceb
Author: OpenClaw <openclaw@swarmclaw.local>
Date:   Thu Mar 12 23:45:17 2026 +0530
Message: feat: add 5 Fibonacci variants - openclaw commit
```

### Run the code

```bash
python3 fibonacci_variants.py
```

Expected:

```
Fibonacci number at position 10:

1. Recursive:             55
2. Memoized:              55
3. Iterative:             55
4. Generator:             55
5. Matrix Exponentiation: 55

All variants produce the same result! ✓
```

### Check diff

```bash
git diff HEAD~1 --stat
```

Expected:

```
 fibonacci_variants.py | 172 +++++++++++++
 1 file changed, 172 insertions(+)
```

---

## Alternative Approaches

### Option A: Use the Web UI

Instead of curl, open **http://localhost:3456** in your browser. The agent and session appear in the sidebar. Just type your task in the chat box.

### Option B: Delegation from another provider

If you prefer using the Anthropic API (not the CLI) as the main provider, you can still delegate to Claude Code:

```bash
curl -s -X POST \
  -H "X-Access-Key: $SC_KEY" \
  -H "Content-Type: application/json" \
  http://localhost:3456/api/agents \
  -d '{
    "name": "API Agent with Claude Code",
    "provider": "anthropic",
    "model": "claude-sonnet-4-5-20250514",
    "tools": ["shell", "files", "claude_code"],
    "systemPrompt": "You are a coding assistant. For complex coding tasks, use the delegate_to_claude_code tool."
  }'
```

This creates an Anthropic API agent that has `delegate_to_claude_code` as a callable tool. When it encounters a coding task, it delegates to Claude Code CLI autonomously.

### Option C: Multi-agent orchestration

Create an orchestrator agent that delegates to specialized sub-agents:

```bash
# 1. Create a coding agent (as above)
# 2. Create an orchestrator
curl -s -X POST \
  -H "X-Access-Key: $SC_KEY" \
  -H "Content-Type: application/json" \
  http://localhost:3456/api/agents \
  -d '{
    "name": "Team Lead",
    "provider": "anthropic",
    "model": "claude-sonnet-4-5-20250514",
    "isOrchestrator": true,
    "subAgentIds": ["CODING_AGENT_ID"],
    "tools": ["orchestrator"]
  }'
```

The orchestrator uses `delegate_to_agent` to assign tasks. SwarmClaw's LangGraph engine handles routing.

### Option D: Connect a messaging platform

Bridge the agent to Telegram, Discord, Slack, or WhatsApp via Connectors (Settings > Connectors in the web UI). Then text the agent from your phone — it takes terminal control the same way.

---

## Security Considerations

| Risk | Mitigation |
|------|-----------|
| **Full shell access** | Claude Code runs with `--dangerously-skip-permissions`. Only use on dedicated/isolated machines. |
| **Git author spoofing** | The `--author` flag lets agents commit as anyone. Use a dedicated identity like `OpenClaw <openclaw@swarmclaw.local>`. |
| **No push by default** | Tasks should explicitly say "do NOT push". Add guardrails in the system prompt. |
| **Credential exposure** | SwarmClaw stores secrets in an AES-256 encrypted vault. Don't put API keys in system prompts. |
| **Runaway processes** | Configurable timeouts: Claude Code Timeout (default 120s, max 7200s), Shell Timeout (default 30s). |
| **Nested spawns** | SwarmClaw strips all `CLAUDE*` env vars before spawning to prevent nested Claude conflicts. |

**Recommended setup for production:**
- Run SwarmClaw on a dedicated machine or VM (not your daily driver)
- Use a separate user account with restricted permissions
- Set `cwd` to a specific project directory, not `~`
- Review commits before pushing to remote

---

## Reference: API Endpoints Used

| # | Method | Endpoint | Purpose |
|---|--------|----------|---------|
| 1 | `POST` | `/api/agents` | Create an agent |
| 2 | `POST` | `/api/sessions` | Create a session with working directory |
| 3 | `POST` | `/api/sessions/{id}/chat` | Send a message (triggers Claude Code) |

**Auth header for all requests:** `X-Access-Key: <your-access-key>`

**Other useful endpoints:**

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/api/agents` | List all agents |
| `GET` | `/api/sessions` | List all sessions |
| `GET` | `/api/sessions/{id}/messages` | Get session message history |
| `POST` | `/api/sessions/{id}/stop` | Stop a running session |
| `DELETE` | `/api/sessions` | Delete sessions (body: `{"ids": [...]}`) |

---

## Appendix: Full Output Trace

This is the exact SSE stream returned from the chat endpoint during our Fibonacci task:

```
data: {"t":"md","text":"{\"run\":{\"id\":\"ff6df3a9904aa3b0\",\"status\":\"queued\",\"position\":0}}"}
data: {"t":"md","text":"{\"run\":{\"id\":\"ff6df3a9904aa3b0\",\"status\":\"running\"}}"}
data: {"t":"md","text":"I'll create the fibonacci_variants.py file with 5 different Fibonacci implementations, test it, and commit it."}
data: {"t":"md","text":"Now let me run it to verify it works:"}
data: {"t":"md","text":"Perfect! Now let me commit it with the specified author and message:"}
data: {"t":"md","text":"✅ Task completed successfully! ..."}
data: {"t":"r","text":"✅ Task completed successfully! ..."}
data: {"t":"md","text":"{\"run\":{\"id\":\"ff6df3a9904aa3b0\",\"status\":\"completed\"}}"}
data: {"t":"done"}
```

**Total execution time:** ~67 seconds (includes Claude Code startup, file creation, python3 test run, and git commit).

---

## Replicating This on a Fresh Machine

```bash
# 1. Install Claude Code
npm install -g @anthropic-ai/claude-code
claude auth login

# 2. Clone and start SwarmClaw
git clone https://github.com/swarmclawai/swarmclaw.git
cd swarmclaw/swarmclaw-app
npm install
npm run dev

# 3. Grab access key
grep ACCESS_KEY ../.env.local

# 4. Run the 3 curl commands from Steps 1-3 above
# 5. Check git log — you'll see the OpenClaw commit
```

---

*Generated from a live session on March 12, 2026. SwarmClaw commit `efad3fc` by agent "OpenClaw Coder".*
