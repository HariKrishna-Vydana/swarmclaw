'use client'

import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog'
import { cn } from '@/lib/utils'
import { api } from '@/lib/api-client'
import { useAppStore } from '@/stores/use-app-store'
import type { Roundtable } from '@/types'

interface CreateRoundtableDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onCreated: (roundtable: Roundtable) => void
}

export function CreateRoundtableDialog({
  open,
  onOpenChange,
  onCreated,
}: CreateRoundtableDialogProps) {
  const [name, setName] = useState('')
  const [topic, setTopic] = useState('')
  const [maxTurns, setMaxTurns] = useState<number | undefined>(10)
  const [selectedAgents, setSelectedAgents] = useState<string[]>([])
  const [loading, setLoading] = useState(false)

  const agentsMap = useAppStore((s) => s.agents)
  const loadAgents = useAppStore((s) => s.loadAgents)
  const agents = Object.values(agentsMap)

  useEffect(() => {
    if (open) {
      loadAgents()
    }
  }, [open, loadAgents])

  const toggleAgent = (agentId: string) => {
    setSelectedAgents((prev) =>
      prev.includes(agentId)
        ? prev.filter((id) => id !== agentId)
        : [...prev, agentId]
    )
  }

  const handleCreate = async () => {
    if (!topic.trim() || selectedAgents.length < 2) return

    setLoading(true)
    try {
      const roundtable = await api<Roundtable>('POST', '/roundtables', {
        name: name.trim() || undefined,
        topic: topic.trim(),
        agentIds: selectedAgents,
        maxTurns: maxTurns || null,
      })

      onCreated(roundtable)
      onOpenChange(false)
      // Reset form
      setName('')
      setTopic('')
      setMaxTurns(10)
      setSelectedAgents([])
    } catch (err) {
      console.error('Failed to create roundtable:', err)
    } finally {
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>New Roundtable Discussion</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-4">
          <div className="space-y-2">
            <label htmlFor="name" className="text-sm font-medium">Name (optional)</label>
            <Input
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Give this discussion a name..."
            />
          </div>

          <div className="space-y-2">
            <label htmlFor="topic" className="text-sm font-medium">Topic *</label>
            <Textarea
              id="topic"
              value={topic}
              onChange={(e) => setTopic(e.target.value)}
              placeholder="What should the agents discuss?"
              rows={3}
            />
          </div>

          <div className="space-y-2">
            <label htmlFor="maxTurns" className="text-sm font-medium">Max Turns (optional)</label>
            <Input
              id="maxTurns"
              type="number"
              min={1}
              value={maxTurns || ''}
              onChange={(e) =>
                setMaxTurns(e.target.value ? parseInt(e.target.value) : undefined)
              }
              placeholder="Leave empty for unlimited"
            />
          </div>

          <div className="space-y-2">
            <label className="text-sm font-medium">Participants * (select at least 2)</label>
            <div className="border rounded-md p-3 max-h-48 overflow-y-auto space-y-2">
              {agents.length === 0 ? (
                <p className="text-sm text-muted-foreground">No agents found. Create agents first.</p>
              ) : (
                agents.map((agent, index) => (
                  <div
                    key={agent.id || `agent-${index}`}
                    className={cn(
                      'flex items-center gap-2 p-2 rounded cursor-pointer hover:bg-muted/50 transition-colors',
                      selectedAgents.includes(agent.id) && 'bg-primary/10 border border-primary/30'
                    )}
                    onClick={() => toggleAgent(agent.id)}
                  >
                    <input
                      type="checkbox"
                      checked={selectedAgents.includes(agent.id)}
                      onChange={() => toggleAgent(agent.id)}
                      className="w-4 h-4 shrink-0"
                    />
                    <div className="flex-1 min-w-0">
                      <span className="font-medium text-sm text-foreground">{agent.name || 'Unnamed Agent'}</span>
                      {agent.description && (
                        <p className="text-xs text-muted-foreground truncate">
                          {agent.description.slice(0, 60)}
                          {agent.description.length > 60 && '...'}
                        </p>
                      )}
                    </div>
                  </div>
                ))
              )}
            </div>
            {selectedAgents.length > 0 && selectedAgents.length < 2 && (
              <p className="text-sm text-yellow-600">Select at least 2 agents</p>
            )}
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button
            onClick={handleCreate}
            disabled={loading || !topic.trim() || selectedAgents.length < 2}
          >
            {loading ? 'Creating...' : 'Start Discussion'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
