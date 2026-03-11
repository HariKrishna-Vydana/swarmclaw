import { NextRequest, NextResponse } from 'next/server'
import { loadRoundtables, saveRoundtables, deleteRoundtable } from '@/lib/server/storage'
import type { Roundtable } from '@/types'

// GET /api/roundtables/[id] - Get a specific roundtable
export async function GET(
  _req: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params
  const roundtables = loadRoundtables() as Record<string, Roundtable>
  const roundtable = roundtables[id]

  if (!roundtable) {
    return NextResponse.json({ error: 'Roundtable not found' }, { status: 404 })
  }

  return NextResponse.json(roundtable)
}

// PATCH /api/roundtables/[id] - Update roundtable (pause, resume, etc.)
export async function PATCH(
  req: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params
  const body = await req.json()
  const roundtables = loadRoundtables() as Record<string, Roundtable>
  const roundtable = roundtables[id]

  if (!roundtable) {
    return NextResponse.json({ error: 'Roundtable not found' }, { status: 404 })
  }

  // Update allowed fields
  if (body.status && ['active', 'paused', 'completed'].includes(body.status)) {
    roundtable.status = body.status
  }
  if (body.name) {
    roundtable.name = body.name
  }
  if (body.maxTurns !== undefined) {
    roundtable.maxTurns = body.maxTurns
  }

  roundtable.updatedAt = Date.now()
  roundtables[id] = roundtable
  saveRoundtables(roundtables)

  return NextResponse.json(roundtable)
}

// DELETE /api/roundtables/[id] - Delete a roundtable
export async function DELETE(
  _req: NextRequest,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params
  const roundtables = loadRoundtables() as Record<string, Roundtable>

  if (!roundtables[id]) {
    return NextResponse.json({ error: 'Roundtable not found' }, { status: 404 })
  }

  deleteRoundtable(id)
  return NextResponse.json({ success: true })
}
