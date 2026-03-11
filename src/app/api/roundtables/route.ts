import { NextRequest, NextResponse } from 'next/server'
import { nanoid } from 'nanoid'
import { loadRoundtables, saveRoundtables, loadAgents, loadSessions, saveSessions } from '@/lib/server/storage'
import type { Roundtable, RoundtableParticipant, Agent, Session } from '@/types'

// GET /api/roundtables - List all roundtables
export async function GET() {
  const roundtables = loadRoundtables()
  return NextResponse.json(Object.values(roundtables))
}

// POST /api/roundtables - Create a new roundtable
export async function POST(req: NextRequest) {
  const body = await req.json()
  const { name, topic, agentIds, maxTurns, moderatorAgentId } = body

  if (!topic || !agentIds || !Array.isArray(agentIds) || agentIds.length < 2) {
    return NextResponse.json(
      { error: 'Topic and at least 2 agent IDs required' },
      { status: 400 }
    )
  }

  const agents = loadAgents() as Record<string, Agent>
  const sessions = loadSessions() as Record<string, Session>
  const roundtables = loadRoundtables()

  // Validate agents exist
  const participants: RoundtableParticipant[] = []
  for (const agentId of agentIds) {
    const agent = agents[agentId]
    if (!agent) {
      return NextResponse.json(
        { error: `Agent ${agentId} not found` },
        { status: 400 }
      )
    }
    participants.push({
      agentId: agent.id,
      agentName: agent.name,
      sessionId: null,
      lastResponseAt: null,
    })
  }

  // Create the main orchestrator session for the roundtable
  const sessionId = nanoid()
  const now = Date.now()

  const session: Session = {
    id: sessionId,
    name: `Roundtable: ${name || topic.slice(0, 30)}`,
    cwd: process.cwd(),
    user: 'system',
    provider: 'openai',
    model: 'gpt-4o',
    claudeSessionId: null,
    messages: [],
    createdAt: now,
    lastActiveAt: now,
    sessionType: 'roundtable',
  }

  sessions[sessionId] = session
  saveSessions(sessions)

  // Create roundtable
  const roundtableId = nanoid()
  const roundtable: Roundtable = {
    id: roundtableId,
    name: name || `Discussion: ${topic.slice(0, 50)}`,
    topic,
    participants,
    messages: [],
    status: 'active',
    currentTurn: 0,
    maxTurns: maxTurns || null,
    moderatorAgentId: moderatorAgentId || null,
    sessionId,
    createdAt: now,
    updatedAt: now,
  }

  roundtables[roundtableId] = roundtable
  saveRoundtables(roundtables)

  return NextResponse.json(roundtable)
}
