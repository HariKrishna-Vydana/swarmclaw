'use client'

import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import { api } from '@/lib/api-client'
import { RoundtableView } from './roundtable-view'
import { CreateRoundtableDialog } from './create-roundtable-dialog'
import type { Roundtable } from '@/types'
import { Plus, MessageSquare, Trash2, Users } from 'lucide-react'

export function RoundtablesPanel() {
  const [roundtables, setRoundtables] = useState<Roundtable[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [showCreate, setShowCreate] = useState(false)
  const [loading, setLoading] = useState(true)

  const loadRoundtables = async () => {
    try {
      const data = await api<Roundtable[]>('GET', '/roundtables')
      setRoundtables(data)
    } catch (err) {
      console.error('Failed to load roundtables:', err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadRoundtables()
  }, [])

  const selectedRoundtable = roundtables.find((r) => r.id === selectedId)

  const handleCreated = (roundtable: Roundtable) => {
    setRoundtables((prev) => [roundtable, ...prev])
    setSelectedId(roundtable.id)
  }

  const handleUpdate = (updated: Roundtable) => {
    setRoundtables((prev) =>
      prev.map((r) => (r.id === updated.id ? updated : r))
    )
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this roundtable discussion?')) return

    try {
      await api('DELETE', `/roundtables/${id}`)
      setRoundtables((prev) => prev.filter((r) => r.id !== id))
      if (selectedId === id) setSelectedId(null)
    } catch (err) {
      console.error('Failed to delete roundtable:', err)
    }
  }

  const getStatusColor = (status: Roundtable['status']) => {
    switch (status) {
      case 'active':
        return 'bg-green-500'
      case 'paused':
        return 'bg-yellow-500'
      case 'completed':
        return 'bg-gray-500'
    }
  }

  return (
    <div className="flex h-full">
      {/* Sidebar */}
      <div className="w-72 border-r flex flex-col">
        <div className="p-4 border-b">
          <Button onClick={() => setShowCreate(true)} className="w-full">
            <Plus className="w-4 h-4 mr-2" />
            New Discussion
          </Button>
        </div>

        <div className="flex-1 overflow-y-auto">
          {loading ? (
            <div className="p-4 text-center text-muted-foreground">Loading...</div>
          ) : roundtables.length === 0 ? (
            <div className="p-4 text-center text-muted-foreground">
              <MessageSquare className="w-8 h-8 mx-auto mb-2 opacity-50" />
              <p>No roundtables yet</p>
              <p className="text-sm">Create one to start a multi-agent discussion</p>
            </div>
          ) : (
            roundtables.map((rt) => (
              <div
                key={rt.id}
                className={cn(
                  'p-3 border-b cursor-pointer hover:bg-muted/50 transition-colors',
                  selectedId === rt.id && 'bg-muted'
                )}
                onClick={() => setSelectedId(rt.id)}
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <div
                        className={cn('w-2 h-2 rounded-full', getStatusColor(rt.status))}
                      />
                      <span className="font-medium text-sm truncate">{rt.name}</span>
                    </div>
                    <p className="text-xs text-muted-foreground truncate mt-1">
                      {rt.topic}
                    </p>
                    <div className="flex items-center gap-2 mt-1 text-xs text-muted-foreground">
                      <Users className="w-3 h-3" />
                      <span>{rt.participants.length}</span>
                      <span>·</span>
                      <span>Turn {rt.currentTurn}</span>
                    </div>
                  </div>
                  <Button
                    variant="ghost"
                    size="icon-xs"
                    onClick={(e) => {
                      e.stopPropagation()
                      handleDelete(rt.id)
                    }}
                  >
                    <Trash2 className="w-3 h-3" />
                  </Button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Main content */}
      <div className="flex-1">
        {selectedRoundtable ? (
          <RoundtableView
            roundtable={selectedRoundtable}
            onUpdate={handleUpdate}
          />
        ) : (
          <div className="h-full flex items-center justify-center text-muted-foreground">
            <div className="text-center">
              <MessageSquare className="w-12 h-12 mx-auto mb-4 opacity-50" />
              <p>Select a roundtable or create a new one</p>
            </div>
          </div>
        )}
      </div>

      <CreateRoundtableDialog
        open={showCreate}
        onOpenChange={setShowCreate}
        onCreated={handleCreated}
      />
    </div>
  )
}
