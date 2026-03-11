import { NextRequest } from 'next/server'
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

// POST /api/roundtables/[id]/stream - SSE streaming discussion turn
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
    return new Response(JSON.stringify({ error: 'Roundtable not found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  if (roundtable.status !== 'active') {
    return new Response(JSON.stringify({ error: 'Roundtable is not active' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const encoder = new TextEncoder()
  const stream = new TransformStream()
  const writer = stream.writable.getWriter()

  const write = (event: string, data: unknown) => {
    writer.write(encoder.encode(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`))
  }

  // Run the discussion asynchronously
  ;(async () => {
    try {
      const agents = loadAgents() as Record<string, Agent>
      const credentials = loadCredentials()

      // Increment turn
      roundtable.currentTurn += 1
      const turnNumber = roundtable.currentTurn

      write('turn_start', { turn: turnNumber })

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
        write('user_message', userMsg)
      }

      // Build context
      const discussionHistory = roundtable.messages
        .map((m) => `[${m.participantName}]: ${m.text}`)
        .join('\n\n')

      // Each agent takes a turn
      for (const participant of roundtable.participants) {
        const agent = agents[participant.agentId]
        if (!agent) continue

        write('agent_start', { agentId: agent.id, agentName: agent.name })

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

        let apiKey: string | null = null
        if (agent.credentialId && credentials[agent.credentialId]) {
          const cred = credentials[agent.credentialId]
          try {
            apiKey = cred.encryptedKey ? decryptKey(cred.encryptedKey) : null
          } catch {
            // continue
          }
        }

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
            write: (chunk: string) => {
              // Parse SSE chunk to extract actual text
              // Format: "data: {"t":"d","text":"actual text"}\n\n"
              const lines = chunk.split('\n')
              for (const line of lines) {
                if (line.startsWith('data: ')) {
                  try {
                    const parsed = JSON.parse(line.slice(6))
                    if (parsed.text) {
                      write('agent_chunk', { agentId: agent.id, text: parsed.text })
                    }
                  } catch {
                    // If not JSON, send raw chunk
                    write('agent_chunk', { agentId: agent.id, text: chunk })
                  }
                }
              }
            },
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
        participant.lastResponseAt = Date.now()

        write('agent_complete', agentMsg)
      }

      // Check max turns
      if (roundtable.maxTurns && roundtable.currentTurn >= roundtable.maxTurns) {
        roundtable.status = 'completed'
      }

      // Detect consensus - check if agents are agreeing
      const turnMessages = roundtable.messages.filter(m => m.turnNumber === turnNumber && m.participantId !== 'user')
      const consensusKeywords = ['agree', 'consensus', 'aligned', 'same page', 'concur', 'exactly right', 'well said', 'good point', 'i think we all', 'we all agree']
      let consensusCount = 0
      for (const msg of turnMessages) {
        const lowerText = msg.text.toLowerCase()
        if (consensusKeywords.some(kw => lowerText.includes(kw))) {
          consensusCount++
        }
      }
      const hasConsensus = turnMessages.length >= 2 && consensusCount >= Math.ceil(turnMessages.length * 0.6)

      roundtable.updatedAt = Date.now()
      const freshRoundtables = loadRoundtables() as Record<string, Roundtable>
      freshRoundtables[id] = roundtable
      saveRoundtables(freshRoundtables)

      write('turn_complete', { turn: turnNumber, status: roundtable.status, consensus: hasConsensus })
    } catch (err) {
      write('error', { message: String(err) })
    } finally {
      writer.close()
    }
  })()

  return new Response(stream.readable, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  })
}
