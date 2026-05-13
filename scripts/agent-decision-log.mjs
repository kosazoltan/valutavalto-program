#!/usr/bin/env node
import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'
import { fileURLToPath } from 'node:url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const repoRoot = path.resolve(__dirname, '..')
const archiveDir = path.join(repoRoot, 'vault', 'agent-archive')
const archivePath = path.join(archiveDir, 'decision-log.jsonl')

function parseArgs(argv) {
  const args = {
    type: 'decision',
    summary: '',
    files: [],
    checks: [],
    status: 'recorded',
    actor: 'codex',
  }
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i]
    const value = argv[i + 1]
    if (!key.startsWith('--')) continue
    i += 1
    const name = key.slice(2)
    if (name === 'files' || name === 'checks') {
      args[name] = value ? value.split(',').map(item => item.trim()).filter(Boolean) : []
    } else if (name in args) {
      args[name] = value ?? ''
    }
  }
  return args
}

function stableStringify(value) {
  if (value === null || typeof value !== 'object') return JSON.stringify(value)
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(',')}]`
  const keys = Object.keys(value).sort()
  return `{${keys.map(key => `${JSON.stringify(key)}:${stableStringify(value[key])}`).join(',')}}`
}

function sha256(text) {
  return crypto.createHash('sha256').update(text).digest('hex')
}

function previousHash() {
  if (!fs.existsSync(archivePath)) return 'GENESIS'
  const lines = fs.readFileSync(archivePath, 'utf8').split(/\r?\n/).filter(Boolean)
  if (lines.length === 0) return 'GENESIS'
  const last = JSON.parse(lines.at(-1))
  return last.hash ?? 'GENESIS'
}

const args = parseArgs(process.argv.slice(2))
if (!args.summary) {
  console.error('Usage: node scripts/agent-decision-log.mjs --summary "..." [--type decision] [--files a,b] [--checks x,y] [--status completed]')
  process.exit(2)
}

fs.mkdirSync(archiveDir, { recursive: true })
const prevHash = previousHash()
const record = {
  schemaVersion: 1,
  at: new Date().toISOString(),
  actor: args.actor,
  type: args.type,
  status: args.status,
  summary: args.summary,
  files: args.files,
  checks: args.checks,
  prevHash,
}
const hash = sha256(`${prevHash}\n${stableStringify(record)}`)
const finalRecord = { ...record, hash }
fs.appendFileSync(archivePath, `${stableStringify(finalRecord)}\n`, 'utf8')
console.log(`[agent-archive] appended vault/agent-archive/decision-log.jsonl hash=${hash}`)
