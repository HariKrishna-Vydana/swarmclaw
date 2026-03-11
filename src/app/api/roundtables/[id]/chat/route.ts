import { NextRequest, NextResponse } from 'next/server'
import { nanoid } from 'nanoid'
import {
  loadRoundtables,
  saveRoundtables,
  loadAgents,
  loadCredentials,
  decryptKey,
} from '@/lib/server/storage'
import { streamChatWithFailover } from '@/lib/providers'
import type { Roundtable, RoundtableMessage, Agent } from '@/types'

// POST /api/roundtables/[id]/chat - Run a discussion turn
// Body: { userMessage?: string } - optional user participation
export async function POST(
  req: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params
  const body = await req.json()
  const { userMessage } = body

  const roundtables = loadRoundtables() as Record<string, Roundtable>
  const roundtable = roundtables[id]

  if (!roundtable) {
    return NextResponse.json({ error: 'Roundtable not found' }, { status: 404 })
  }

  if (roundtable.status !== 'active') {
    return NextResponse.json(
      { error: 'Roundtable is not active' },
      { status: 400 }
    )
  }

  const agents = loadAgents() as Record<string, Agent>
  const credentials = loadCredentials()

  // Increment turn
  roundtable.currentTurn += 1
  const turnNumber = roundtable.currentTurn

  // Add user message if provided
  if (userMessage) {
    const userMsg: RoundtableMessage = {
      id: nanoid(),
      participantId: 'user',
      participantName: 'You',
      text: userMessage,
      turnNumber,
      createdAt: Date.now(),
    }
    roundtable.messages.push(userMsg)
  }

  // Build context for agents
  const discussionHistory = roundtable.messages
    .map((m) => `[${m.participantName}]: ${m.text}`)
    .join('\n\n')

  const responses: RoundtableMessage[] = []

  // Each agent takes a turn
  for (const participant of roundtable.participants) {
    const agent = agents[participant.agentId]
    if (!agent) continue

    // Build system prompt for the agent
    const otherParticipants = roundtable.participants
      .filter((p) => p.agentId !== agent.id)
      .map((p) => `- ${p.agentName}`)
      .join('\n')

    const systemPrompt = `${agent.systemPrompt || ''}

You are participating in a roundtable discussion about: "${roundtable.topic}"

Other participants:
${otherParticipants}
- You (the user) may also participate

This is turn ${turnNumber} of the discussion.

Previous discussion:
${discussionHistory || '(No messages yet - you are starting the discussion)'}

Please provide your perspective on the topic. Be concise but insightful. Build on or respectfully disagree with what others have said.

IMPORTANT: Keep your response to a MAXIMUM of 3 lines (about 2-3 sentences). Be brief and direct.`

    const message = userMessage
      ? `The user just said: "${userMessage}"\n\nPlease respond with your thoughts on the topic and the user's input.`
      : `Please share your perspective on "${roundtable.topic}" for this turn of the discussion.`

    // Get API key for agent
    let apiKey: string | null = null
    if (agent.credentialId && credentials[agent.credentialId]) {
      const cred = credentials[agent.credentialId]
      try {
        apiKey = cred.encryptedKey ? decryptKey(cred.encryptedKey) : null
      } catch {
        // continue without key
      }
    }

    // Stream chat and collect response
    let responseText = ''
    try {
      responseText = await streamChatWithFailover({
        session: {
          id: `roundtable-${id}-${agent.id}`,
          provider: agent.provider,
          model: agent.model,
          apiEndpoint: agent.apiEndpoint,
          credentialId: agent.credentialId,
          fallbackCredentialIds: agent.fallbackCredentialIds,
        },
        message,
        apiKey,
        systemPrompt,
        write: () => {}, // No streaming for roundtable
        active: new Map(),
        loadHistory: () => [],
      })
    } catch (err) {
      console.error(`[roundtable] Error from agent ${agent.name}:`, err)
      responseText = `[Error: Could not get response from ${agent.name}]`
    }

    const agentMsg: RoundtableMessage = {
      id: nanoid(),
      participantId: agent.id,
      participantName: agent.name,
      text: responseText,
      turnNumber,
      createdAt: Date.now(),
    }

    roundtable.messages.push(agentMsg)
    responses.push(agentMsg)

    // Update participant's last response time
    participant.lastResponseAt = Date.now()
  }

  // Check if we've reached max turns
  if (roundtable.maxTurns && roundtable.currentTurn >= roundtable.maxTurns) {
    roundtable.status = 'completed'
  }

  roundtable.updatedAt = Date.now()
  roundtables[id] = roundtable
  saveRoundtables(roundtables)

  return NextResponse.json({
    turn: turnNumber,
    responses,
    roundtable,
  })
}
