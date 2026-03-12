#!/usr/bin/env node
/**
 * Show messages stored in SwarmClaw's SQLite database
 * Usage: node scripts/show-messages.mjs [--sessions | --roundtables | --all] [--limit N]
 */

import Database from 'better-sqlite3'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const DB_PATH = path.join(__dirname, '..', 'data', 'swarmclaw.db')

const args = process.argv.slice(2)
const showSessions = args.includes('--sessions') || args.includes('--all') || (!args.includes('--roundtables'))
const showRoundtables = args.includes('--roundtables') || args.includes('--all')
const limitIdx = args.indexOf('--limit')
const msgLimit = limitIdx !== -1 ? parseInt(args[limitIdx + 1], 10) || 5 : 5

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  cyan: '\x1b[36m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
}

function formatDate(ts) {
  return new Date(ts).toLocaleString()
}

function truncate(str, len = 100) {
  if (!str) return ''
  const clean = str.replace(/\n/g, ' ').trim()
  return clean.length > len ? clean.slice(0, len) + '...' : clean
}

try {
  const db = new Database(DB_PATH, { readonly: true })

  if (showSessions) {
    console.log(`\n${colors.bright}${colors.cyan}=== SESSIONS ===${colors.reset}\n`)

    const sessions = db.prepare('SELECT id, data FROM sessions').all()
    const parsed = sessions
      .map(row => ({ id: row.id, ...JSON.parse(row.data) }))
      .sort((a, b) => (b.lastActiveAt || 0) - (a.lastActiveAt || 0))

    if (parsed.length === 0) {
      console.log('  No sessions found.\n')
    } else {
      console.log(`  Total: ${parsed.length} sessions\n`)

      for (const s of parsed) {
        const msgCount = s.messages?.length || 0
        const statusIcon = s.active ? '🟢' : '⚪'

        console.log(`${statusIcon} ${colors.bright}${s.name}${colors.reset}`)
        console.log(`   ${colors.dim}ID: ${s.id}${colors.reset}`)
        console.log(`   ${colors.dim}Agent: ${s.agentId || '(none)'} | Provider: ${s.provider} | Model: ${s.model || '(default)'}${colors.reset}`)
        console.log(`   ${colors.dim}Messages: ${msgCount} | Last Active: ${formatDate(s.lastActiveAt)}${colors.reset}`)

        if (msgCount > 0) {
          const recentMsgs = s.messages.slice(-msgLimit)
          console.log(`   ${colors.yellow}Last ${recentMsgs.length} message(s):${colors.reset}`)
          for (const m of recentMsgs) {
            const roleColor = m.role === 'user' ? colors.green : colors.blue
            const toolInfo = m.toolEvents?.length ? ` [${m.toolEvents.length} tools]` : ''
            console.log(`     ${roleColor}[${m.role}]${colors.reset}${toolInfo} ${truncate(m.text, 80)}`)
          }
        }
        console.log('')
      }
    }
  }

  if (showRoundtables) {
    console.log(`\n${colors.bright}${colors.magenta}=== ROUNDTABLES ===${colors.reset}\n`)

    const roundtables = db.prepare('SELECT id, data FROM roundtables').all()

    if (roundtables.length === 0) {
      console.log('  No roundtables found.\n')
    } else {
      console.log(`  Total: ${roundtables.length} roundtables\n`)

      for (const row of roundtables) {
        const rt = JSON.parse(row.data)
        const msgCount = rt.messages?.length || 0
        const statusIcon = rt.status === 'active' ? '🟢' : rt.status === 'completed' ? '✅' : '⏸️'

        console.log(`${statusIcon} ${colors.bright}${rt.name}${colors.reset}`)
        console.log(`   ${colors.dim}ID: ${row.id}${colors.reset}`)
        console.log(`   ${colors.dim}Topic: ${truncate(rt.topic, 60)}${colors.reset}`)
        console.log(`   ${colors.dim}Participants: ${(rt.participants || []).map(p => p.agentName).join(', ')}${colors.reset}`)
        console.log(`   ${colors.dim}Messages: ${msgCount} | Turn: ${rt.currentTurn || 0}${rt.maxTurns ? '/' + rt.maxTurns : ''}${colors.reset}`)

        if (msgCount > 0) {
          const recentMsgs = rt.messages.slice(-msgLimit)
          console.log(`   ${colors.yellow}Last ${recentMsgs.length} message(s):${colors.reset}`)
          for (const m of recentMsgs) {
            const roleColor = m.participantId === 'user' ? colors.green : colors.blue
            console.log(`     ${roleColor}[${m.participantName}]${colors.reset} ${truncate(m.text, 70)}`)
          }
        }
        console.log('')
      }
    }
  }

  // Summary stats
  console.log(`${colors.bright}=== SUMMARY ===${colors.reset}`)
  const sessionCount = db.prepare('SELECT COUNT(*) as c FROM sessions').get().c
  const rtCount = db.prepare('SELECT COUNT(*) as c FROM roundtables').get().c

  let totalSessionMsgs = 0
  let totalRtMsgs = 0

  const allSessions = db.prepare('SELECT data FROM sessions').all()
  for (const row of allSessions) {
    const s = JSON.parse(row.data)
    totalSessionMsgs += s.messages?.length || 0
  }

  const allRts = db.prepare('SELECT data FROM roundtables').all()
  for (const row of allRts) {
    const rt = JSON.parse(row.data)
    totalRtMsgs += rt.messages?.length || 0
  }

  console.log(`  Sessions: ${sessionCount} (${totalSessionMsgs} total messages)`)
  console.log(`  Roundtables: ${rtCount} (${totalRtMsgs} total messages)`)
  console.log(`  Database: ${DB_PATH}\n`)

  db.close()
} catch (err) {
  console.error('Error:', err.message)
  process.exit(1)
}
