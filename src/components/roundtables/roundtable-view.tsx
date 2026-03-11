'use client'

import { useState, useRef, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { cn } from '@/lib/utils'
import { api, getStoredAccessKey } from '@/lib/api-client'
import type { Roundtable, RoundtableMessage } from '@/types'
import { Send, Pause, Play, Users, MessageCircle, PlayCircle, StopCircle } from 'lucide-react'

interface RoundtableViewProps {
  roundtable: Roundtable
  onUpdate: (roundtable: Roundtable) => void
}

export function RoundtableView({ roundtable, onUpdate }: RoundtableViewProps) {
  const [userMessage, setUserMessage] = useState('')
  const [isRunning, setIsRunning] = useState(false)
  const [autoRunning, setAutoRunning] = useState(false)
  const [consensusReached, setConsensusReached] = useState(false)
  const [streamingAgent, setStreamingAgent] = useState<string | null>(null)
  const [streamingText, setStreamingText] = useState('')
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const stopRef = useRef(false)

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  useEffect(() => {
    scrollToBottom()
  }, [roundtable.messages, streamingText])

  const runTurn = async (message?: string): Promise<{ consensus: boolean; stopped: boolean }> => {
    if (isRunning || roundtable.status !== 'active') return { consensus: false, stopped: true }

    setIsRunning(true)
    setStreamingText('')
    let hasConsensus = false

    try {
      const accessKey = getStoredAccessKey()
      const res = await fetch(`/api/roundtables/${roundtable.id}/stream`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(accessKey ? { 'x-access-key': accessKey } : {}),
        },
        body: JSON.stringify({ userMessage: message }),
      })

      if (!res.ok) {
        throw new Error('Failed to run turn')
      }

      const reader = res.body?.getReader()
      const decoder = new TextDecoder()

      if (!reader) return { consensus: false, stopped: true }

      let buffer = ''
      while (true) {
        const { done, value } = await reader.read()
        if (done) break

        buffer += decoder.decode(value, { stream: true })
        const lines = buffer.split('\n')
        buffer = lines.pop() || ''

        for (const line of lines) {
          if (line.startsWith('event: ')) {
            continue
          }
          if (line.startsWith('data: ')) {
            try {
              const data = JSON.parse(line.slice(6))
              handleSSEEvent(data)
              // Check for consensus in turn_complete event
              if (data.consensus) {
                hasConsensus = true
              }
            } catch {
              // ignore parse errors
            }
          }
        }
      }

      // Refresh roundtable after turn
      try {
        const updated = await api<Roundtable>('GET', `/roundtables/${roundtable.id}`)
        onUpdate(updated)
      } catch {
        // ignore refresh errors
      }
    } catch (err) {
      console.error('Error running turn:', err)
    } finally {
      setIsRunning(false)
      setStreamingAgent(null)
      setStreamingText('')
    }

    return { consensus: hasConsensus, stopped: stopRef.current }
  }

  const startAutoRun = async () => {
    setAutoRunning(true)
    setConsensusReached(false)
    stopRef.current = false

    while (!stopRef.current && roundtable.status === 'active') {
      const result = await runTurn()

      if (result.consensus) {
        setConsensusReached(true)
        break
      }

      if (result.stopped || stopRef.current) {
        break
      }

      // Small delay between turns
      await new Promise(resolve => setTimeout(resolve, 500))
    }

    setAutoRunning(false)
  }

  const stopAutoRun = () => {
    stopRef.current = true
    setAutoRunning(false)
  }

  const handleSSEEvent = (data: any) => {
    if (data.agentId && data.agentName && !data.text) {
      // agent_start
      setStreamingAgent(data.agentName)
      setStreamingText('')
    } else if (data.agentId && data.text) {
      // agent_chunk
      setStreamingText((prev) => prev + data.text)
    } else if (data.participantId) {
      // agent_complete or user_message
      setStreamingAgent(null)
      setStreamingText('')
    }
  }

  const handleSend = () => {
    if (!userMessage.trim()) return
    const msg = userMessage.trim()
    setUserMessage('')
    runTurn(msg)
  }

  const togglePause = async () => {
    const newStatus = roundtable.status === 'paused' ? 'active' : 'paused'
    try {
      const updated = await api<Roundtable>('PATCH', `/roundtables/${roundtable.id}`, { status: newStatus })
      onUpdate(updated)
    } catch (err) {
      console.error('Failed to toggle pause:', err)
    }
  }

  const getParticipantColor = (participantId: string) => {
    if (participantId === 'user') return 'bg-blue-500/10 border-blue-500/30'
    const idx = roundtable.participants.findIndex((p) => p.agentId === participantId)
    const colors = [
      'bg-purple-500/10 border-purple-500/30',
      'bg-green-500/10 border-green-500/30',
      'bg-orange-500/10 border-orange-500/30',
      'bg-pink-500/10 border-pink-500/30',
      'bg-cyan-500/10 border-cyan-500/30',
    ]
    return colors[idx % colors.length]
  }

  const groupedMessages = roundtable.messages.reduce(
    (acc, msg) => {
      const turn = msg.turnNumber
      if (!acc[turn]) acc[turn] = []
      acc[turn].push(msg)
      return acc
    },
    {} as Record<number, RoundtableMessage[]>
  )

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b">
        <div>
          <h2 className="text-lg font-semibold">{roundtable.name}</h2>
          <p className="text-sm text-muted-foreground">{roundtable.topic}</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex items-center gap-1 text-sm text-muted-foreground">
            <Users className="w-4 h-4" />
            <span>{roundtable.participants.length} participants</span>
          </div>
          <div className="text-sm text-muted-foreground">
            Turn {roundtable.currentTurn}
            {roundtable.maxTurns && ` / ${roundtable.maxTurns}`}
          </div>
          {roundtable.status !== 'completed' && (
            <Button variant="outline" size="sm" onClick={togglePause}>
              {roundtable.status === 'paused' ? (
                <>
                  <Play className="w-4 h-4" /> Resume
                </>
              ) : (
                <>
                  <Pause className="w-4 h-4" /> Pause
                </>
              )}
            </Button>
          )}
        </div>
      </div>

      {/* Participants */}
      <div className="flex gap-2 p-3 border-b bg-muted/30 overflow-x-auto">
        {roundtable.participants.map((p) => (
          <div
            key={p.agentId}
            className={cn(
              'px-3 py-1.5 rounded-full text-sm border',
              getParticipantColor(p.agentId),
              streamingAgent === p.agentName && 'ring-2 ring-primary'
            )}
          >
            {p.agentName}
          </div>
        ))}
        <div className={cn('px-3 py-1.5 rounded-full text-sm border', getParticipantColor('user'))}>
          You
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-6">
        {Object.entries(groupedMessages).map(([turn, messages]) => (
          <div key={turn} className="space-y-3">
            <div className="flex items-center gap-2">
              <div className="h-px flex-1 bg-border" />
              <span className="text-xs text-muted-foreground px-2">Turn {turn}</span>
              <div className="h-px flex-1 bg-border" />
            </div>
            {messages.map((msg) => (
              <div
                key={msg.id}
                className={cn(
                  'p-3 rounded-lg border',
                  getParticipantColor(msg.participantId)
                )}
              >
                <div className="flex items-center gap-2 mb-2">
                  <MessageCircle className="w-4 h-4" />
                  <span className="font-medium text-sm">{msg.participantName}</span>
                  <span className="text-xs text-muted-foreground">
                    {new Date(msg.createdAt).toLocaleTimeString()}
                  </span>
                </div>
                <p className="text-sm whitespace-pre-wrap">{msg.text}</p>
              </div>
            ))}
          </div>
        ))}

        {/* Streaming indicator */}
        {streamingAgent && (
          <div
            className={cn(
              'p-3 rounded-lg border',
              getParticipantColor(
                roundtable.participants.find((p) => p.agentName === streamingAgent)?.agentId || ''
              )
            )}
          >
            <div className="flex items-center gap-2 mb-2">
              <MessageCircle className="w-4 h-4 animate-pulse" />
              <span className="font-medium text-sm">{streamingAgent}</span>
              <span className="text-xs text-muted-foreground">typing...</span>
            </div>
            <p className="text-sm whitespace-pre-wrap">{streamingText || '...'}</p>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      {roundtable.status === 'active' && (
        <div className="p-4 border-t">
          <div className="flex gap-2">
            <Input
              value={userMessage}
              onChange={(e) => setUserMessage(e.target.value)}
              placeholder="Join the discussion or press 'Next Turn' to let agents continue..."
              onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleSend()}
              disabled={isRunning}
            />
            <Button onClick={handleSend} disabled={isRunning || !userMessage.trim()}>
              <Send className="w-4 h-4" />
            </Button>
            <Button
              variant="outline"
              onClick={() => runTurn()}
              disabled={isRunning}
            >
              {isRunning ? 'Running...' : 'Next Turn'}
            </Button>
          </div>
        </div>
      )}

      {roundtable.status === 'completed' && (
        <div className="p-4 border-t bg-muted/50 text-center text-muted-foreground">
          Discussion completed after {roundtable.currentTurn} turns
        </div>
      )}

      {roundtable.status === 'paused' && (
        <div className="p-4 border-t bg-yellow-500/10 text-center text-yellow-600 dark:text-yellow-400">
          Discussion paused
        </div>
      )}
    </div>
  )
}
